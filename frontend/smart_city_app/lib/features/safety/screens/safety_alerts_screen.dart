import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/safety_alert_model.dart';
import '../providers/safety_provider.dart';
import '../widgets/safety_alert_card.dart';
import '../widgets/safety_message_view.dart';
import 'safety_alert_details_screen.dart';

/// Entry point for the Safety Alerts feature.
/// Creates the provider, so it can be opened from anywhere:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyAlertsScreen()));
class SafetyAlertsScreen extends StatelessWidget {
  const SafetyAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SafetyProvider()..loadAlerts(),
      child: const _AlertsView(),
    );
  }
}

void _openDetails(BuildContext context, SafetyAlert alert) {
  final provider = context.read<SafetyProvider>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: SafetyAlertDetailsScreen(alert: alert),
      ),
    ),
  );
}

class _AlertsView extends StatelessWidget {
  const _AlertsView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SafetyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Alerts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => p.loadAlerts(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Active'),
                    icon: Icon(Icons.notifications_active_outlined),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Previous'),
                    icon: Icon(Icons.history),
                  ),
                ],
                selected: {p.showActiveAlerts},
                onSelectionChanged: (s) => p.setAlertsTab(s.first),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip(p, 'All', null),
                _chip(p, 'Critical', 'critical'),
                _chip(p, 'High', 'high'),
                _chip(p, 'Medium', 'medium'),
                _chip(p, 'Low', 'low'),
              ],
            ),
          ),
          SizedBox(
            height: 3,
            child: p.isLoadingAlerts ? const LinearProgressIndicator() : null,
          ),
          Expanded(child: _buildList(context, p)),
        ],
      ),
    );
  }

  Widget _chip(SafetyProvider p, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: p.severityFilter == value,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        onSelected: (_) => p.setSeverityFilter(value),
      ),
    );
  }

  Widget _buildList(BuildContext context, SafetyProvider p) {
    if (p.isLoadingAlerts && p.alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.alertsError != null) {
      return SafetyMessageView(
        icon: Icons.cloud_off,
        message: p.alertsError!,
        actionLabel: 'Try again',
        onAction: () => p.loadAlerts(),
      );
    }
    if (p.alerts.isEmpty) {
      return SafetyMessageView(
        icon: Icons.check_circle_outline,
        message: p.showActiveAlerts
            ? 'No active safety alerts right now.'
            : 'No previous alerts found.',
      );
    }

    return RefreshIndicator(
      onRefresh: p.loadAlerts,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: p.alerts.length,
        itemBuilder: (context, index) {
          final alert = p.alerts[index];
          return SafetyAlertCard(
            alert: alert,
            onTap: () => _openDetails(context, alert),
          );
        },
      ),
    );
  }
}
