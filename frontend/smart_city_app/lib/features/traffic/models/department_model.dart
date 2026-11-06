import 'traffic_issue_model.dart';

class DepartmentInfo {
  final int id;
  final String name;
  final String? description;
  final String? responsibilities;
  final String? contactEmail;
  final String? contactPhone;
  final String? officeAddress;
  final String? officeCity;
  final double? officeLatitude;
  final double? officeLongitude;
  final String? operatingHours;
  final int trafficIssueCount;

  const DepartmentInfo({
    required this.id,
    required this.name,
    this.description,
    this.responsibilities,
    this.contactEmail,
    this.contactPhone,
    this.officeAddress,
    this.officeCity,
    this.officeLatitude,
    this.officeLongitude,
    this.operatingHours,
    required this.trafficIssueCount,
  });

  factory DepartmentInfo.fromJson(Map<String, dynamic> json) => DepartmentInfo(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        responsibilities: json['responsibilities'] as String?,
        contactEmail: json['contact_email'] as String?,
        contactPhone: json['contact_phone'] as String?,
        officeAddress: json['office_address'] as String?,
        officeCity: json['office_city'] as String?,
        officeLatitude: (json['office_latitude'] as num?)?.toDouble(),
        officeLongitude: (json['office_longitude'] as num?)?.toDouble(),
        operatingHours: json['operating_hours'] as String?,
        trafficIssueCount: json['traffic_issue_count'] as int,
      );

  bool get hasValidCoordinates =>
      officeLatitude != null && officeLongitude != null &&
      officeLatitude! >= -90 && officeLatitude! <= 90 &&
      officeLongitude! >= -180 && officeLongitude! <= 180;
}

class DepartmentPage {
  final List<DepartmentInfo> items;
  final int total;
  final int limit;
  final int offset;

  const DepartmentPage({required this.items, required this.total, required this.limit, required this.offset});

  factory DepartmentPage.fromJson(Map<String, dynamic> json) => DepartmentPage(
        items: (json['items'] as List<dynamic>)
            .map((item) => DepartmentInfo.fromJson(item as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        limit: json['limit'] as int,
        offset: json['offset'] as int,
      );
}

class DepartmentTrafficPage {
  final List<TrafficIssue> items;
  final int total;
  final int limit;
  final int offset;

  const DepartmentTrafficPage({required this.items, required this.total, required this.limit, required this.offset});

  factory DepartmentTrafficPage.fromJson(Map<String, dynamic> json) => DepartmentTrafficPage(
        items: (json['items'] as List<dynamic>)
            .map((item) => TrafficIssue.fromJson(item as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        limit: json['limit'] as int,
        offset: json['offset'] as int,
      );
}
