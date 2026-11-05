
class IssueDetails {
  final int id;
  final String title;
  final String description;
  final String category;
  final String? subcategory;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IssueLocationDetails? location;
  final DepartmentDetails? department;
  final List<IssueAttachmentDetails> attachments;
  final List<AIAnalysisDetails> aiAnalysis;
  final List<SimilarReportDetails> similarReports;
  final List<IssueStatusDetails> statusTimeline;

  IssueDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.subcategory,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.department,
    required this.attachments,
    required this.aiAnalysis,
    required this.similarReports,
    required this.statusTimeline,
  });

  factory IssueDetails.fromJson(Map<String, dynamic> json) {
    return IssueDetails(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      location: json['location'] == null
          ? null
          : IssueLocationDetails.fromJson(json['location']),
      department: json['department'] == null
          ? null
          : DepartmentDetails.fromJson(json['department']),
      attachments: (json['attachments'] as List? ?? [])
          .map((e) => IssueAttachmentDetails.fromJson(e))
          .toList(),
      aiAnalysis: (json['ai_analysis'] as List? ?? [])
          .map((e) => AIAnalysisDetails.fromJson(e))
          .toList(),
      similarReports: (json['similar_reports'] as List? ?? [])
          .map((e) => SimilarReportDetails.fromJson(e))
          .toList(),
      statusTimeline: (json['status_timeline'] as List? ?? [])
          .map((e) => IssueStatusDetails.fromJson(e))
          .toList(),
    );
  }
}

class IssueLocationDetails {
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;

  IssueLocationDetails.fromJson(Map<String, dynamic> json)
      : latitude = (json['latitude'] as num?)?.toDouble(),
        longitude = (json['longitude'] as num?)?.toDouble(),
        address = json['address'],
        city = json['city'];
}

class DepartmentDetails {
  final int id;
  final String name;

  DepartmentDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'] ?? '';
}

class IssueAttachmentDetails {
  final int id;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final DateTime createdAt;

  IssueAttachmentDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        fileName = json['file_name'] ?? '',
        fileUrl = json['file_url'] ?? '',
        fileType = json['file_type'],
        createdAt = DateTime.parse(json['created_at']);
}

class AIAnalysisDetails {
  final int id;
  final String analysisType;
  final dynamic result;
  final String? explanation;
  final String? modelName;
  final int? confidenceScore;
  final DateTime createdAt;

  AIAnalysisDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        analysisType = json['analysis_type'] ?? '',
        result = json['result'],
        explanation = json['explanation'],
        modelName = json['model_name'],
        confidenceScore = (json['confidence_score'] as num?)?.toInt(),
        createdAt = DateTime.parse(json['created_at']);
}

class SimilarReportDetails {
  final int id;
  final String title;
  final String category;
  final String status;
  final String priority;
  final double? similarityScore;

  SimilarReportDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'] ?? '',
        category = json['category'] ?? '',
        status = json['status'] ?? '',
        priority = json['priority'] ?? '',
        similarityScore = (json['similarity_score'] as num?)?.toDouble();
}

class IssueStatusDetails {
  final int id;
  final String? previousStatus;
  final String newStatus;
  final String? note;
  final DateTime createdAt;

  IssueStatusDetails.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        previousStatus = json['previous_status'],
        newStatus = json['new_status'] ?? '',
        note = json['note'],
        createdAt = DateTime.parse(json['created_at']);
}
