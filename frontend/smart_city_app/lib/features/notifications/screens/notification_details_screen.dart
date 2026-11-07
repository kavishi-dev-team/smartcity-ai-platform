import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../models/notification_model.dart';

class NotificationDetailsScreen extends StatefulWidget {
  final NotificationModel notification;
  final Future<NotificationModel> Function() loadNotification;
  final Future<NotificationModel> Function() onMarkAsRead;

  const NotificationDetailsScreen({
    super.key,
    required this.notification,
    required this.loadNotification,
    required this.onMarkAsRead,
  });

  @override
  State<NotificationDetailsScreen> createState() =>
      _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  late NotificationModel _item;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _item = widget.notification;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final item = await widget.loadNotification();
      if (!mounted) return;
      setState(() => _item = item);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead() async {
    setState(() => _saving = true);

    try {
      final item = await widget.onMarkAsRead();
      if (!mounted) return;
      setState(() => _item = item);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notification details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ] else ...[
                        Text(
                          _item.title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_item.category} • ${_item.date}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _item.message,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _item.isRead || _saving
                              ? null
                              : _markAsRead,
                          icon: Icon(
                            _item.isRead
                                ? Icons.done_all
                                : Icons.mark_email_read,
                          ),
                          label: Text(
                            _saving
                                ? 'Saving...'
                                : _item.isRead
                                ? 'Already read'
                                : 'Mark as read',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
