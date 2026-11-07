import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/traffic_issue_model.dart';

class TrafficIssueCard extends StatelessWidget {
  final TrafficIssue issue;
  final VoidCallback onTap;

  const TrafficIssueCard({super.key, required this.issue, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final location = issue.location;
    final locationText = (location?.address?.isNotEmpty == true)
        ? location!.address!
        : (location?.city?.isNotEmpty == true ? location!.city! : 'Location not provided');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
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
                    child: Text(issue.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
              const SizedBox(height: 7),
              Text(issue.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _ChipText(text: trafficLabel(issue.priority), color: _priorityColor),
                _ChipText(text: trafficLabel(issue.status), color: AppColors.primary),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 17, color: AppColors.muted),
                const SizedBox(width: 5),
                Expanded(child: Text(locationText, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 7),
              Text('Reported ${trafficDate(issue.createdAt)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  final String text;
  final Color color;
  const _ChipText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}
