class RelatedIssue {
  final int id;
  final String title;
  final String category;
  final String status;

  const RelatedIssue({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
  });

  factory RelatedIssue.fromJson(Map<String, dynamic> json) {
    return RelatedIssue(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
    );
  }
}

class SafetyAlert {
  final int id;
  final String title;
  final String description;
  final String alertType;
  final String severity; // low | medium | high | critical
  final String area;
  final String? safetyInstructions;
  final int? issueId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RelatedIssue? relatedIssue; // only filled by the detail endpoint

  const SafetyAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.alertType,
    required this.severity,
    required this.area,
    this.safetyInstructions,
    this.issueId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.relatedIssue,
  });

  /// "road_hazard" -> "Road Hazard"
  String get alertTypeLabel => alertType
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    final related = json['related_issue'];
    return SafetyAlert(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      alertType: json['alert_type'] as String,
      severity: json['severity'] as String,
      area: json['area'] as String,
      safetyInstructions: json['safety_instructions'] as String?,
      issueId: (json['issue_id'] as num?)?.toInt(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      relatedIssue: related == null
          ? null
          : RelatedIssue.fromJson(related as Map<String, dynamic>),
    );
  }
}
