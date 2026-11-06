import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/safety_alert_model.dart';
import '../utils/safety_formatters.dart';

const Color _orange = Color(0xFFF97316);

/// Colour for an alert severity: low | medium | high | critical.
Color severityColor(String severity) {
  switch (severity) {
    case 'critical':
      return AppColors.error;
    case 'high':
      return _orange;
    case 'medium':
      return AppColors.warning;
    default:
      return AppColors.primary;
  }
}

IconData alertTypeIcon(String type) {
  switch (type) {
    case 'flood':
      return Icons.water_drop_outlined;
    case 'fire':
      return Icons.local_fire_department;
    case 'air_quality':
      return Icons.air;
    case 'gas_leak':
      return Icons.local_gas_station;
    case 'road_hazard':
      return Icons.traffic;
    case 'landslide':
      return Icons.terrain;
    case 'infrastructure':
      return Icons.construction;
    case 'public_health':
      return Icons.health_and_safety_outlined;
    default:
      return Icons.warning_amber_rounded;
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 30) return '${diff.inDays} d ago';
  return formatShortDate(dt);
}

class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.toUpperCase(),
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

class SafetyAlertCard extends StatelessWidget {
  final SafetyAlert alert;
  final VoidCallback onTap;

  const SafetyAlertCard({super.key, required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(alert.severity);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(alertTypeIcon(alert.alertType), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            alert.area,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SeverityBadge(severity: alert.severity),
                        Text(
                          _timeAgo(alert.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
