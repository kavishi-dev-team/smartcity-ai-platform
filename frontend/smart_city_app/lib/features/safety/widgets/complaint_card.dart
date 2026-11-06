import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/safety_issue_model.dart';
import '../utils/safety_formatters.dart';
import 'safety_alert_card.dart'; // SeverityBadge
import 'safety_issue_card.dart'; // SafetyStatusChip

/// One complaint in the history list.
class ComplaintCard extends StatelessWidget {
  final SafetyIssue issue;
  final VoidCallback onTap;

  const ComplaintCard({super.key, required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    issue.reference,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  SeverityBadge(severity: issue.priority),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                issue.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                issue.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SafetyStatusChip(status: issue.status),
                  const Spacer(),
                  if (issue.city != null) ...[
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      issue.city!,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    formatRelative(issue.updatedAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
