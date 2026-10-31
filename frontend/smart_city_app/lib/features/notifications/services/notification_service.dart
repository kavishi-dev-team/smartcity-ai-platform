import '../models/notification_model.dart';

class NotificationService {
  List<NotificationModel> getSampleNotifications() {
    return const [
      NotificationModel(
        id: 'N-001',
        title: 'Waste report update',
        message:
            'Your bulky waste pickup report is now in progress. '
            'Further updates will appear here.',
        category: 'Report update',
        date: '2026-10-20',
        reportId: 'WR-2048',
      ),
      NotificationModel(
        id: 'N-002',
        title: 'Recycling reminder',
        message:
            'Check your area’s collection schedule and prepare '
            'accepted recyclable materials separately.',
        category: 'Collection reminder',
        date: '2026-10-20',
      ),
      NotificationModel(
        id: 'N-003',
        title: 'Waste report resolved',
        message:
            'Your missed collection report has been marked '
            'as resolved in this demo.',
        category: 'Report update',
        date: '2026-10-19',
        reportId: 'WR-2037',
        isRead: true,
      ),
    ];
  }
}
