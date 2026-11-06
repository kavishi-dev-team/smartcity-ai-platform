import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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

/// One row of the "Safety problems overview" table.
class SafetyIssueRow extends StatelessWidget {
  final SafetyIssue issue;
  final VoidCallback onTap;

  const SafetyIssueRow({super.key, required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.reference,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Updated ${formatRelative(issue.updatedAt)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                  ),
                  const SizedBox(height: 4),
                  SafetyStatusChip(status: issue.status),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_horiz, color: AppColors.muted),
              onSelected: (_) => onTap(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'view', child: Text('View details')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
