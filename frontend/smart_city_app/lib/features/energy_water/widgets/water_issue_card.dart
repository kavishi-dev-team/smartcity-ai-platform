import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../../auth/providers/auth_provider.dart';
import '../../traffic/models/traffic_issue_model.dart';
import '../../traffic/screens/traffic_status_management_screen.dart';
import '../models/water_issue_model.dart';

class WaterIssueCard extends StatelessWidget {
  final WaterIssue issue;
  final VoidCallback? onTap;

  const WaterIssueCard({super.key, required this.issue, this.onTap});

  Color _priorityColor() {
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
    final isStaff = context.watch<AuthProvider>().user?.isStaff ?? false;
    final locationText = (issue.address?.isNotEmpty == true)
        ? issue.address!
        : (issue.city?.isNotEmpty == true
              ? issue.city!
              : 'Location not provided');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                  _chip(trafficLabel(issue.priority), _priorityColor()),
                  _chip(trafficLabel(issue.status), AppColors.primary),
                  if (issue.isLeakage) _chip('Leakage', AppColors.cyan),
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
                      'Report #${issue.id} • Reported ${trafficDate(issue.createdAt)}',
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TrafficStatusManagementScreen(
                              issueId: issue.id,
                              categoryLabel: 'Water',
                            ),
                          ),
                        );
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

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
