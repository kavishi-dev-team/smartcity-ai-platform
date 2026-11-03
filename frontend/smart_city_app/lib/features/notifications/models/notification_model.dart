class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String category;
  final String date;
  final String? reportId;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.date,
    this.reportId,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);

    return NotificationModel(
      id: (json['id'] as int).toString(),
      title: json['title'] as String,
      message: json['message'] as String,
      category: (json['notification_type'] as String).replaceAll('_', ' '),
      date:
          '${createdAt.year}-'
          '${createdAt.month.toString().padLeft(2, '0')}-'
          '${createdAt.day.toString().padLeft(2, '0')}',
      isRead: json['is_read'] as bool,
    );
  }

  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      category: category,
      date: date,
      reportId: reportId,
      isRead: true,
    );
  }
}
