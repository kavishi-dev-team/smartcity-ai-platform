import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import 'notification_details_screen.dart';
import 'notification_preferences_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _provider = NotificationProvider();

  bool _unreadOnly = false;

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Notification preferences',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, child) {
          if (_provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = _provider.notifications.where((item) {
            return !_unreadOnly || !item.isRead;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_provider.storageError != null) ...[
                      Text(
                        _provider.storageError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () {
                              _provider.loadReadStatus();
                            },
                            child: const Text('Retry loading'),
                          ),
                          TextButton(
                            onPressed: () {
                              _provider.saveReadStatus();
                            },
                            child: const Text('Retry saving'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Your updates',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_provider.unreadCount} unread notifications',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('Unread only'),
                          selected: _unreadOnly,
                          onSelected: (value) {
                            setState(() => _unreadOnly = value);
                          },
                        ),
                        TextButton.icon(
                          onPressed: _provider.unreadCount == 0
                              ? null
                              : _provider.markAllAsRead,
                          icon: const Icon(Icons.done_all),
                          label: const Text('Mark all as read'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 44,
                                color: AppColors.muted,
                              ),
                              SizedBox(height: 12),
                              Text('No notifications to show.'),
                            ],
                          ),
                        ),
                      )
                    else
                      ...items.map(
                        (item) => NotificationCard(
                          notification: item,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => NotificationDetailsScreen(
                                  notification: item,
                                  onMarkAsRead: () {
                                    _provider.markAsRead(item.id);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
