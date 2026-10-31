import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../../waste/screens/waste_problem_details_screen.dart';
import '../models/notification_model.dart';

class NotificationDetailsScreen extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onMarkAsRead;

  const NotificationDetailsScreen({
    super.key,
    required this.notification,
    required this.onMarkAsRead,
  });

  @override
  State<NotificationDetailsScreen> createState() =>
      _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  late bool _isRead;

  // Temporary sample reports until the backend is connected.
  static const Map<String, Map<String, String>> _sampleReports = {
    'WR-2052': {
      'id': 'WR-2052',
      'title': 'Missed recycling',
      'status': 'Pending',
      'location': 'Colombo 07',
    },
    'WR-2048': {
      'id': 'WR-2048',
      'title': 'Bulky waste pickup',
      'status': 'In progress',
      'location': 'Nugegoda',
    },
    'WR-2041': {
      'id': 'WR-2041',
      'title': 'Bin replacement',
      'status': 'Pending',
      'location': 'Homagama',
    },
    'WR-2037': {
      'id': 'WR-2037',
      'title': 'Missed collection',
      'status': 'Resolved',
      'location': 'Maharagama',
    },
  };

  @override
  void initState() {
    super.initState();
    _isRead = widget.notification.isRead;
  }

  void _markAsRead() {
    if (_isRead) return;

    widget.onMarkAsRead();
    setState(() => _isRead = true);
  }

  void _openReport() {
    final reportId = widget.notification.reportId?.trim();
    final issue = _sampleReports[reportId];

    if (issue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The related report is not available.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WasteProblemDetailsScreen(issue: issue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.notification;
    final reportId = item.reportId?.trim();
    final hasReport = reportId != null && reportId.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notification details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${item.category} • ${item.date}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      item.message,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                if (hasReport) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Related waste report',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reportId,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _openReport,
                          icon: const Icon(Icons.assignment_outlined),
                          label: const Text('View report'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isRead ? null : _markAsRead,
                  icon: Icon(_isRead ? Icons.done_all : Icons.mark_email_read),
                  label: Text(_isRead ? 'Already read' : 'Mark as read'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
