class AnalyticsOverview {
  final int totalIssues;
  final int pendingIssues;
  final int inProgressIssues;
  final int resolvedIssues;
  final int highPriorityIssues;

  AnalyticsOverview({
    required this.totalIssues,
    required this.pendingIssues,
    required this.inProgressIssues,
    required this.resolvedIssues,
    required this.highPriorityIssues,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      totalIssues: json['total_issues'] ?? 0,
      pendingIssues: json['pending_issues'] ?? 0,
      inProgressIssues: json['in_progress_issues'] ?? 0,
      resolvedIssues: json['resolved_issues'] ?? 0,
      highPriorityIssues: json['high_priority_issues'] ?? 0,
    );
  }
}

class CategoryAnalytics {
  final String category;
  final int issueCount;

  CategoryAnalytics({
    required this.category,
    required this.issueCount,
  });

  factory CategoryAnalytics.fromJson(Map<String, dynamic> json) {
    return CategoryAnalytics(
      category: json['category'] ?? '',
      issueCount: json['issue_count'] ?? 0,
    );
  }
}

class StatusAnalytics {
  final String status;
  final int issueCount;

  StatusAnalytics({
    required this.status,
    required this.issueCount,
  });

  factory StatusAnalytics.fromJson(Map<String, dynamic> json) {
    return StatusAnalytics(
      status: json['status'] ?? '',
      issueCount: json['issue_count'] ?? 0,
    );
  }
}

class MonthlyAnalytics {
  final String month;
  final int issueCount;

  MonthlyAnalytics({
    required this.month,
    required this.issueCount,
  });

  factory MonthlyAnalytics.fromJson(Map<String, dynamic> json) {
    return MonthlyAnalytics(
      month: json['month'] ?? '',
      issueCount: json['issue_count'] ?? 0,
    );
  }
}

class IssueAnalytics {
  final List<CategoryAnalytics> categories;
  final List<StatusAnalytics> statuses;
  final List<MonthlyAnalytics> monthly;

  IssueAnalytics({
    required this.categories,
    required this.statuses,
    required this.monthly,
  });

  factory IssueAnalytics.fromJson(Map<String, dynamic> json) {
    return IssueAnalytics(
      categories: (json['categories'] as List? ?? [])
          .map((item) => CategoryAnalytics.fromJson(item))
          .toList(),
      statuses: (json['statuses'] as List? ?? [])
          .map((item) => StatusAnalytics.fromJson(item))
          .toList(),
      monthly: (json['monthly'] as List? ?? [])
          .map((item) => MonthlyAnalytics.fromJson(item))
          .toList(),
    );
  }
}

class DepartmentAnalytics {
  final int departmentId;
  final String departmentName;
  final int totalIssues;
  final int pendingIssues;
  final int resolvedIssues;

  DepartmentAnalytics({
    required this.departmentId,
    required this.departmentName,
    required this.totalIssues,
    required this.pendingIssues,
    required this.resolvedIssues,
  });

  factory DepartmentAnalytics.fromJson(Map<String, dynamic> json) {
    return DepartmentAnalytics(
      departmentId: json['department_id'] ?? 0,
      departmentName: json['department_name'] ?? '',
      totalIssues: json['total_issues'] ?? 0,
      pendingIssues: json['pending_issues'] ?? 0,
      resolvedIssues: json['resolved_issues'] ?? 0,
    );
  }
}

class DepartmentAnalyticsResponse {
  final List<DepartmentAnalytics> departments;

  DepartmentAnalyticsResponse({
    required this.departments,
  });

  factory DepartmentAnalyticsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepartmentAnalyticsResponse(
      departments: (json['departments'] as List? ?? [])
          .map((item) => DepartmentAnalytics.fromJson(item))
          .toList(),
    );
  }
}
