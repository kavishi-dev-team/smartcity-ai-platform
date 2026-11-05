class DashboardIssue {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String priority;
  final int? departmentId;
  final DateTime createdAt;

  DashboardIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    this.departmentId,
    required this.createdAt,
  });

  factory DashboardIssue.fromJson(Map<String, dynamic> json) {
    return DashboardIssue(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      status: json['status'],
      priority: json['priority'],
      departmentId: json['department_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class CitizenDashboard {
  final int totalReports;
  final int activeReports;
  final int resolvedReports;
  final List<DashboardIssue> recentReports;

  CitizenDashboard({
    required this.totalReports,
    required this.activeReports,
    required this.resolvedReports,
    required this.recentReports,
  });

  factory CitizenDashboard.fromJson(Map<String, dynamic> json) {
    return CitizenDashboard(
      totalReports: json['total_reports'],
      activeReports: json['active_reports'],
      resolvedReports: json['resolved_reports'],
      recentReports: (json['recent_reports'] as List)
          .map((item) => DashboardIssue.fromJson(item))
          .toList(),
    );
  }
}

class DashboardStatistics {
  final int total;
  final int pending;
  final int highPriority;
  final int inProgress;
  final int resolved;

  DashboardStatistics({
    required this.total,
    required this.pending,
    required this.highPriority,
    required this.inProgress,
    required this.resolved,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      total: json['total'],
      pending: json['pending'],
      highPriority: json['high_priority'],
      inProgress: json['in_progress'],
      resolved: json['resolved'],
    );
  }
}

class OfficerDashboard {
  final DashboardStatistics statistics;
  final List<DashboardIssue> recentIssues;

  OfficerDashboard({
    required this.statistics,
    required this.recentIssues,
  });

  factory OfficerDashboard.fromJson(Map<String, dynamic> json) {
    return OfficerDashboard(
      statistics: DashboardStatistics.fromJson(json['statistics']),
      recentIssues: (json['recent_issues'] as List)
          .map((item) => DashboardIssue.fromJson(item))
          .toList(),
    );
  }
}
