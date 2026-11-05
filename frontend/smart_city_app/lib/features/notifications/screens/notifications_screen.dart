import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../widgets/notification_card.dart';
import 'notification_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final NotificationService? service;

  const NotificationsScreen({super.key, this.service});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationProvider _provider;
  bool _unreadOnly = false;

  @override
  void initState() {
    super.initState();
    _provider = NotificationProvider(service: widget.service);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _markAll() async {
    try {
      await _provider.markAllAsRead();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          ListenableBuilder(
            listenable: _provider,
            builder: (context, child) {
              return IconButton(
                tooltip: 'Refresh notifications',
                onPressed: _provider.isLoading || _provider.isSaving
                    ? null
                    : _provider.loadNotifications,
                icon: const Icon(Icons.refresh),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, child) {
          if (_provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _provider.loadNotifications,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = _provider.notifications
              .where((item) => !_unreadOnly || !item.isRead)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          onPressed:
                              _provider.unreadCount == 0 || _provider.isSaving
                              ? null
                              : _markAll,
                          icon: const Icon(Icons.done_all),
                          label: Text(
                            _provider.isSaving
                                ? 'Saving...'
                                : 'Mark all as read',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text('No notifications to show.')),
                      )
                    else
                      ...items.map(
                        (item) => NotificationCard(
                          notification: item,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => NotificationDetailsScreen(
                                  notification: item,
                                  loadNotification: () =>
                                      _provider.getNotification(item.id),
                                  onMarkAsRead: () =>
                                      _provider.markAsRead(item.id),
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
