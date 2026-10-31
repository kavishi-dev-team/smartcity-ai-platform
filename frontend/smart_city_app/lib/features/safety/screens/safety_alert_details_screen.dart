import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/safety_alert_model.dart';
import '../providers/safety_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/safety_alert_card.dart';

class SafetyAlertDetailsScreen extends StatefulWidget {
  /// The alert tapped in the list. Shown immediately while the full details load.
  final SafetyAlert alert;

  const SafetyAlertDetailsScreen({super.key, required this.alert});

  @override
  State<SafetyAlertDetailsScreen> createState() =>
      _SafetyAlertDetailsScreenState();
}

class _SafetyAlertDetailsScreenState extends State<SafetyAlertDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SafetyProvider>().loadAlertDetail(widget.alert.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SafetyProvider>();
    final loaded = p.alertDetail;
    final alert =
        (loaded != null && loaded.id == widget.alert.id) ? loaded : widget.alert;
    final color = severityColor(alert.severity);

    return Scaffold(
      appBar: AppBar(title: const Text('Alert Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.detailError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                p.detailError!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SeverityBadge(severity: alert.severity),
                      const SizedBox(width: 8),
                      _StatusChip(isActive: alert.isActive),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Affected area',
                    value: alert.area,
                  ),
                  _InfoRow(
                    icon: alertTypeIcon(alert.alertType),
                    label: 'Alert type',
                    value: alert.alertTypeLabel,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Description',
            icon: Icons.description_outlined,
            child: Text(
              alert.description,
              style: const TextStyle(color: AppColors.text, height: 1.4),
            ),
          ),
          if (alert.safetyInstructions != null &&
              alert.safetyInstructions!.trim().isNotEmpty)
            _Section(
              title: 'Safety instructions',
              icon: Icons.health_and_safety_outlined,
              accent: color,
              child: Text(
                alert.safetyInstructions!,
                style: const TextStyle(color: AppColors.text, height: 1.4),
              ),
            ),
          _Section(
            title: 'Date and time',
            icon: Icons.schedule,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Issued: ${formatDateTime(alert.createdAt)}'),
                const SizedBox(height: 4),
                Text('Last updated: ${formatDateTime(alert.updatedAt)}'),
              ],
            ),
          ),
          if (alert.issueId != null)
            _Section(
              title: 'Related issue',
              icon: Icons.link,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (alert.relatedIssue != null) ...[
                    Text(
                      alert.relatedIssue!.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${alert.relatedIssue!.category} \u2022 ${alert.relatedIssue!.status}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ] else if (p.isLoadingDetail)
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text('Issue #${alert.issueId}'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      // TODO: open the shared report details screen
                      // (features/reporting) once the reporting module is ready.
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Issue #${alert.issueId} will open in the shared report details screen.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View related issue'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'RESOLVED',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: AppColors.muted)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accent;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = accent ?? AppColors.primary;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: accent == null ? null : accent!.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
