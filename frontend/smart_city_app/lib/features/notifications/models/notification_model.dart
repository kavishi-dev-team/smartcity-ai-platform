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
