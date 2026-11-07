class SafetySummary {
  final int activeAlerts;
  final int openReports;
  final int resolvedTotal;
  final int? resolvedInSlaPercent; // null when nothing has been resolved yet
  final int slaHours;
  final DateTime updatedAt;

  const SafetySummary({
    required this.activeAlerts,
    required this.openReports,
    required this.resolvedTotal,
    this.resolvedInSlaPercent,
    required this.slaHours,
    required this.updatedAt,
  });

  factory SafetySummary.fromJson(Map<String, dynamic> json) {
    return SafetySummary(
      activeAlerts: (json['active_alerts'] as num).toInt(),
      openReports: (json['open_reports'] as num).toInt(),
      resolvedTotal: (json['resolved_total'] as num).toInt(),
      resolvedInSlaPercent: (json['resolved_in_sla_percent'] as num?)?.toInt(),
      slaHours: (json['sla_hours'] as num).toInt(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// How many reports are in each status (complaint history tabs).
class IssueCounts {
  final int total;
  final int reported;
  final int underReview;
  final int assigned;
  final int inProgress;
  final int resolved;
  final int rejected;

  const IssueCounts({
    this.total = 0,
    this.reported = 0,
    this.underReview = 0,
    this.assigned = 0,
    this.inProgress = 0,
    this.resolved = 0,
    this.rejected = 0,
  });

  factory IssueCounts.fromJson(Map<String, dynamic> json) {
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return IssueCounts(
      total: n('total'),
      reported: n('reported'),
      underReview: n('under_review'),
      assigned: n('assigned'),
      inProgress: n('in_progress'),
      resolved: n('resolved'),
      rejected: n('rejected'),
    );
  }
}

class SafetyIssue {
  final int id;
  final String reference; // e.g. SF-2217 or CP-12
  final String title;
  final String description;
  final String category;
  final String status;
  final String priority;
  final String? address;
  final String? city;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SafetyIssue({
    required this.id,
    required this.reference,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    this.address,
    this.city,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafetyIssue.fromJson(Map<String, dynamic> json) {
    return SafetyIssue(
      id: (json['id'] as num).toInt(),
      reference: json['reference'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class SafetyIssuePage {
  final List<SafetyIssue> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const SafetyIssuePage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory SafetyIssuePage.fromJson(Map<String, dynamic> json) {
    return SafetyIssuePage(
      items: (json['items'] as List<dynamic>)
          .map((e) => SafetyIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      totalPages: (json['total_pages'] as num).toInt(),
    );
  }
}

class SafetyLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;

  const SafetyLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
  });

  factory SafetyLocation.fromJson(Map<String, dynamic> json) {
    return SafetyLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
    );
  }
}

/// One step of the timeline. When [previousStatus] == [newStatus] it is a plain
/// update (a message from the officer) and the status did not change.
class StatusHistoryEntry {
  final String? previousStatus;
  final String newStatus;
  final String? note;
  final DateTime createdAt;

  const StatusHistoryEntry({
    this.previousStatus,
    required this.newStatus,
    this.note,
    required this.createdAt,
  });

  bool get isPlainUpdate => previousStatus != null && previousStatus == newStatus;

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SafetyDepartment {
  final int id;
  final String name;

  const SafetyDepartment({required this.id, required this.name});

  factory SafetyDepartment.fromJson(Map<String, dynamic> json) {
    return SafetyDepartment(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}

class SafetyOfficer {
  final int id;
  final String fullName;
  final String? position;

  const SafetyOfficer({required this.id, required this.fullName, this.position});

  factory SafetyOfficer.fromJson(Map<String, dynamic> json) {
    return SafetyOfficer(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String,
      position: json['position'] as String?,
    );
  }
}

class SafetyAssignment {
  final int departmentId;
  final String? departmentName;
  final int assignedTo;
  final String? assignedToName;
  final String? assignedByName;
  final String status;
  final String? note;
  final DateTime assignedAt;

  const SafetyAssignment({
    required this.departmentId,
    this.departmentName,
    required this.assignedTo,
    this.assignedToName,
    this.assignedByName,
    required this.status,
    this.note,
    required this.assignedAt,
  });

  factory SafetyAssignment.fromJson(Map<String, dynamic> json) {
    return SafetyAssignment(
      departmentId: (json['department_id'] as num).toInt(),
      departmentName: json['department_name'] as String?,
      assignedTo: (json['assigned_to'] as num).toInt(),
      assignedToName: json['assigned_to_name'] as String?,
      assignedByName: json['assigned_by_name'] as String?,
      status: json['status'] as String,
      note: json['note'] as String?,
      assignedAt: DateTime.parse(json['assigned_at'] as String),
    );
  }
}

class SafetyAttachment {
  final int id;
  final String fileName;
  final String fileUrl;
  final String? fileType;

  const SafetyAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
  });

  bool get isImage {
    final type = (fileType ?? '').toLowerCase();
    final url = fileUrl.toLowerCase();
    return type.startsWith('image') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.webp') ||
        url.contains('picsum.photos');
  }

  factory SafetyAttachment.fromJson(Map<String, dynamic> json) {
    return SafetyAttachment(
      id: (json['id'] as num).toInt(),
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String?,
    );
  }
}

/// Written by the AI module; we only display it.
class SafetyAiAnalysis {
  final String analysisType;
  final String? recommendedPriority;
  final String? explanation;
  final int? confidenceScore;
  final String? modelName;
  final DateTime createdAt;

  const SafetyAiAnalysis({
    required this.analysisType,
    this.recommendedPriority,
    this.explanation,
    this.confidenceScore,
    this.modelName,
    required this.createdAt,
  });

  factory SafetyAiAnalysis.fromJson(Map<String, dynamic> json) {
    return SafetyAiAnalysis(
      analysisType: json['analysis_type'] as String,
      recommendedPriority: json['recommended_priority'] as String?,
      explanation: json['explanation'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toInt(),
      modelName: json['model_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Staff-only note.
class InternalNote {
  final int id;
  final String? authorName;
  final String note;
  final DateTime createdAt;

  const InternalNote({
    required this.id,
    this.authorName,
    required this.note,
    required this.createdAt,
  });

  factory InternalNote.fromJson(Map<String, dynamic> json) {
    return InternalNote(
      id: (json['id'] as num).toInt(),
      authorName: json['author_name'] as String?,
      note: json['note'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SafetyIssueDetail {
  final SafetyIssue issue;
  final SafetyLocation? location;
  final List<StatusHistoryEntry> history;
  final SafetyDepartment? department;
  final SafetyAssignment? assignment;
  final List<SafetyAttachment> attachments;
  final SafetyAiAnalysis? aiAnalysis;
  final List<SafetyIssue> related;

  const SafetyIssueDetail({
    required this.issue,
    this.location,
    required this.history,
    this.department,
    this.assignment,
    this.attachments = const [],
    this.aiAnalysis,
    this.related = const [],
  });

  factory SafetyIssueDetail.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final department = json['department'];
    final assignment = json['assignment'];
    final analysis = json['ai_analysis'];
    return SafetyIssueDetail(
      issue: SafetyIssue.fromJson(json),
      location: location == null
          ? null
          : SafetyLocation.fromJson(location as Map<String, dynamic>),
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      department: department == null
          ? null
          : SafetyDepartment.fromJson(department as Map<String, dynamic>),
      assignment: assignment == null
          ? null
          : SafetyAssignment.fromJson(assignment as Map<String, dynamic>),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) => SafetyAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      aiAnalysis: analysis == null
          ? null
          : SafetyAiAnalysis.fromJson(analysis as Map<String, dynamic>),
      related: (json['related'] as List<dynamic>? ?? [])
          .map((e) => SafetyIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
