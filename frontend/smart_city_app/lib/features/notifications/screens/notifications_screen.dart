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

          final totalCount = _provider.notifications.length;
          final unreadCount = _provider.unreadCount;
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.14),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'City Updates & Alerts',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$unreadCount unread • $totalCount total notifications',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (unreadCount > 0)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: _provider.isSaving ? null : _markAll,
                              icon: const Icon(Icons.done_all_rounded, size: 17),
                              label: Text(
                                _provider.isSaving
                                    ? 'Saving...'
                                    : 'Mark All Read',
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ChoiceChip(
                          label: Text('All Updates ($totalCount)'),
                          selected: !_unreadOnly,
                          onSelected: (_) {
                            setState(() => _unreadOnly = false);
                          },
                        ),
                        ChoiceChip(
                          label: Text('Unread Only ($unreadCount)'),
                          selected: _unreadOnly,
                          onSelected: (_) {
                            setState(() => _unreadOnly = true);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (items.isEmpty)
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 40,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.notifications_paused_outlined,
                                  size: 46,
                                  color: AppColors.skyBlue,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _unreadOnly
                                      ? 'You are all caught up!'
                                      : 'No notifications yet',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _unreadOnly
                                      ? 'There are no unread notifications right now.'
                                      : 'Case status updates and safety advisories will appear here.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
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
