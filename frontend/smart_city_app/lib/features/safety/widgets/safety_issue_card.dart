import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../traffic/models/traffic_issue_model.dart';
import '../../traffic/screens/traffic_status_management_screen.dart';
import '../models/safety_issue_model.dart';
import '../utils/safety_formatters.dart';

const List<String> safetyStatuses = [
  'reported',
  'under_review',
  'assigned',
  'in_progress',
  'resolved',
  'rejected',
];

const List<String> safetyPriorities = ['low', 'medium', 'high', 'critical'];

String statusLabel(String status) {
  switch (status) {
    case 'reported':
      return 'Reported';
    case 'under_review':
      return 'Under review';
    case 'assigned':
      return 'Assigned';
    case 'in_progress':
      return 'In progress';
    case 'resolved':
      return 'Resolved';
    case 'rejected':
      return 'Rejected';
    default:
      return status;
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'resolved':
      return AppColors.success;
    case 'rejected':
      return AppColors.error;
    case 'under_review':
      return AppColors.warning;
    case 'in_progress':
      return AppColors.cyan;
    case 'assigned':
      return AppColors.primary;
    default:
      return AppColors.muted;
  }
}

/// Small dot + label, e.g. "• In progress".
class SafetyStatusChip extends StatelessWidget {
  final String status;
  const SafetyStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          statusLabel(status),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Traffic-style card for each item in the "Safety problems overview" list.
class SafetyIssueRow extends StatelessWidget {
  final SafetyIssue issue;
  final VoidCallback onTap;
  final VoidCallback? onUpdated;

  const SafetyIssueRow({
    super.key,
    required this.issue,
    required this.onTap,
    this.onUpdated,
  });

  Color get _priorityColor {
    switch (issue.priority.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isStaff = context.watch<AuthProvider>().user?.isStaff ?? false;
    final locationText = (issue.address?.isNotEmpty == true)
        ? issue.address!
        : (issue.city?.isNotEmpty == true
              ? issue.city!
              : 'Location not provided');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      issue.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                issue.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(trafficLabel(issue.priority), _priorityColor),
                  _chip(statusLabel(issue.status), AppColors.primary),
                  _chip(issue.reference, AppColors.primaryDark),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      locationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Updated ${formatRelative(issue.updatedAt)} • Reported ${trafficDate(issue.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isStaff)
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.lightBlue,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TrafficStatusManagementScreen(
                              issueId: issue.id,
                              categoryLabel: 'Safety',
                            ),
                          ),
                        );
                        onUpdated?.call();
                      },
                      icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                      label: const Text(
                        'Manage Case',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
