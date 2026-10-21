import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: onTap,
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none
              : Icons.notifications_active_outlined,
          color: AppColors.primary,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: AppColors.text,
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${notification.category}\n'
            '${notification.date} • '
            '${notification.isRead ? 'Read' : 'Unread'}',
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
