class TrafficLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;

  const TrafficLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
  });

  factory TrafficLocation.fromJson(Map<String, dynamic> json) {
    return TrafficLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
    );
  }
}

class TrafficIssue {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String priority;
  final int? departmentId;
  final String? departmentName;
  final TrafficLocation? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrafficIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    this.departmentId,
    this.departmentName,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrafficIssue.fromJson(Map<String, dynamic> json) {
    final rawLocation = json['location'];
    return TrafficIssue(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      departmentId: json['department_id'] as int?,
      departmentName: json['department_name'] as String?,
      location: rawLocation == null
          ? null
          : TrafficLocation.fromJson(rawLocation as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class TrafficIssuePage {
  final List<TrafficIssue> items;
  final int total;
  final int limit;
  final int offset;

  const TrafficIssuePage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TrafficIssuePage.fromJson(Map<String, dynamic> json) {
    return TrafficIssuePage(
      items: (json['items'] as List<dynamic>)
          .map((item) => TrafficIssue.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }
}

class TrafficPhoto {
  final int id;
  final String fileName;
  final String fileUrl;

  const TrafficPhoto({required this.id, required this.fileName, required this.fileUrl});

  factory TrafficPhoto.fromJson(Map<String, dynamic> json) {
    return TrafficPhoto(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
    );
  }
}

class TrafficHistoryItem {
  final String? previousStatus;
  final String newStatus;
  final String? note;
  final DateTime createdAt;

  const TrafficHistoryItem({
    this.previousStatus,
    required this.newStatus,
    this.note,
    required this.createdAt,
  });

  factory TrafficHistoryItem.fromJson(Map<String, dynamic> json) {
    return TrafficHistoryItem(
      previousStatus: json['previous_status'] as String?,
      newStatus: json['new_status'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TrafficIssueDetail {
  final TrafficIssue issue;
  final List<TrafficPhoto> photos;
  final List<TrafficHistoryItem> statusHistory;
  final String? aiSummary;
  final List<TrafficIssue> similarIssues;

  const TrafficIssueDetail({
    required this.issue,
    required this.photos,
    required this.statusHistory,
    required this.aiSummary,
    required this.similarIssues,
  });

  factory TrafficIssueDetail.fromJson(Map<String, dynamic> json) {
    return TrafficIssueDetail(
      issue: TrafficIssue.fromJson(json),
      photos: ((json['photos'] as List<dynamic>?) ?? [])
          .map((item) => TrafficPhoto.fromJson(item as Map<String, dynamic>))
          .toList(),
      statusHistory: ((json['status_history'] as List<dynamic>?) ?? [])
          .map((item) => TrafficHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      aiSummary: json['ai_summary'] as String?,
      similarIssues: ((json['similar_issues'] as List<dynamic>?) ?? [])
          .map((item) => TrafficIssue.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

String trafficDate(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String trafficLabel(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

/// A map pin based on a real traffic issue and its most recent valid location.
class TrafficMapMarker {
  final int id;
  final String title;
  final String status;
  final String priority;
  final TrafficLocation location;

  const TrafficMapMarker({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.location,
  });

  factory TrafficMapMarker.fromJson(Map<String, dynamic> json) {
    return TrafficMapMarker(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      location: TrafficLocation.fromJson(json['location'] as Map<String, dynamic>),
    );
  }
}

class TrafficMapPage {
  final List<TrafficMapMarker> items;
  final int total;
  final int limit;

  const TrafficMapPage({required this.items, required this.total, required this.limit});

  factory TrafficMapPage.fromJson(Map<String, dynamic> json) => TrafficMapPage(
    items: (json['items'] as List<dynamic>)
        .map((item) => TrafficMapMarker.fromJson(item as Map<String, dynamic>))
        .toList(),
    total: json['total'] as int,
    limit: json['limit'] as int,
  );
}
