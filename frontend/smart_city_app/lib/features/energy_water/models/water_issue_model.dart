class WaterIssue {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String priority;
  final int? departmentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final bool isLeakage;

  const WaterIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    this.departmentId,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.isLeakage = false,
  });

  factory WaterIssue.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return WaterIssue(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      departmentId: json['department_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      latitude: (location?['latitude'] as num?)?.toDouble(),
      longitude: (location?['longitude'] as num?)?.toDouble(),
      address: location?['address'] as String?,
      city: location?['city'] as String?,
      isLeakage: (json['subcategory'] as String?) == 'leakage',
    );
  }
}