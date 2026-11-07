class OfficerChoice {
  final int id;
  final String name;
  const OfficerChoice({required this.id, required this.name});

  factory OfficerChoice.fromJson(Map<String, dynamic> data) => OfficerChoice(
        id: data['id'] as int,
        name: data['name'] as String,
      );
}

class TrafficOfficerNote {
  final int id;
  final String comment;
  final String visibility;
  final String authorName;
  final DateTime createdAt;

  const TrafficOfficerNote({
    required this.id,
    required this.comment,
    required this.visibility,
    required this.authorName,
    required this.createdAt,
  });

  factory TrafficOfficerNote.fromJson(Map<String, dynamic> json) =>
      TrafficOfficerNote(
        id: json['id'] as int,
        comment: json['comment'] as String,
        visibility: json['visibility'] as String,
        authorName: json['author_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class TrafficPriorityReview {
  final String aiSuggestedPriority;
  final String finalPriority;
  final String reviewStatus;
  final String? reviewNote;

  const TrafficPriorityReview({
    required this.aiSuggestedPriority,
    required this.finalPriority,
    required this.reviewStatus,
    this.reviewNote,
  });

  factory TrafficPriorityReview.fromJson(Map<String, dynamic> json) =>
      TrafficPriorityReview(
        aiSuggestedPriority: json['ai_suggested_priority'] as String,
        finalPriority: json['final_priority'] as String,
        reviewStatus: json['review_status'] as String,
        reviewNote: json['review_note'] as String?,
      );
}

class TrafficOfficerIssue {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final int? departmentId;
  final String? departmentName;
  final int? assignedOfficerId;
  final String? assignedOfficerName;
  final String? aiRecommendedPriority;
  final TrafficPriorityReview? latestPriorityReview;
  final List<OfficerChoice> departments;
  final List<OfficerChoice> officers;
  final List<TrafficOfficerNote> notes;

  const TrafficOfficerIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.departmentId,
    this.departmentName,
    this.assignedOfficerId,
    this.assignedOfficerName,
    this.aiRecommendedPriority,
    this.latestPriorityReview,
    required this.departments,
    required this.officers,
    required this.notes,
  });

  factory TrafficOfficerIssue.fromJson(Map<String, dynamic> json) {
    final review = json['latest_priority_review'];
    return TrafficOfficerIssue(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      departmentId: json['department_id'] as int?,
      departmentName: json['department_name'] as String?,
      assignedOfficerId: json['assigned_officer_id'] as int?,
      assignedOfficerName: json['assigned_officer_name'] as String?,
      aiRecommendedPriority: json['ai_recommended_priority'] as String?,
      latestPriorityReview: review == null
          ? null
          : TrafficPriorityReview.fromJson(review as Map<String, dynamic>),
      departments: (json['departments'] as List<dynamic>)
          .map((item) => OfficerChoice.fromJson(item as Map<String, dynamic>))
          .toList(),
      officers: (json['officers'] as List<dynamic>)
          .map((item) => OfficerChoice.fromJson(item as Map<String, dynamic>))
          .toList(),
      notes: (json['notes'] as List<dynamic>)
          .map((item) => TrafficOfficerNote.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
