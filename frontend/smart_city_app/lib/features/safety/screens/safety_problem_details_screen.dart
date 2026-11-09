import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../reporting/widgets/issue_location_tracker_card.dart';
import '../../traffic/screens/department_information_screen.dart';
import '../../traffic/screens/traffic_status_management_screen.dart';
import '../models/safety_issue_model.dart';
import '../providers/safety_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/safety_alert_card.dart';
import '../widgets/safety_issue_card.dart';

class SafetyProblemDetailsScreen extends StatefulWidget {
  final SafetyIssue issue;

  const SafetyProblemDetailsScreen({super.key, required this.issue});

  @override
  State<SafetyProblemDetailsScreen> createState() =>
      _SafetyProblemDetailsScreenState();
}

class _SafetyProblemDetailsScreenState
    extends State<SafetyProblemDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SafetyProvider>().loadProblemDetail(widget.issue.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SafetyProvider>();
    final detail = p.problemDetail;
    final loaded =
        (detail != null && detail.issue.id == widget.issue.id) ? detail : null;
    final issue = loaded?.issue ?? widget.issue;
    final loading = p.isLoadingProblemDetail && loaded == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Safety Problem • ${issue.reference}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<SafetyProvider>().loadProblemDetail(issue.id),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (p.problemDetailError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    p.problemDetailError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              // Traffic-style Header Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 9,
                        runSpacing: 8,
                        children: [
                          SafetyStatusChip(status: issue.status),
                          SeverityBadge(severity: issue.priority),
                          Chip(label: Text('Ref: ${issue.reference}')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Report #${issue.id}  •  Reported ${formatDateTime(issue.createdAt)}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              StaffCaseManagementBanner(
                issueId: issue.id,
                categoryLabel: 'Safety',
                currentStatus: issue.status,
                currentPriority: issue.priority,
                onUpdated: () {
                  if (mounted) {
                    context.read<SafetyProvider>().loadProblemDetail(issue.id);
                    context.read<SafetyProvider>().loadProblemsScreen();
                  }
                },
              ),
              _Section(
                title: 'Problem Description',
                icon: Icons.description_outlined,
                child: Text(
                  issue.description,
                  style: const TextStyle(color: AppColors.text, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              IssueLocationTrackerCard(
                title: issue.title,
                category: 'safety',
                address: loaded?.location?.address ?? issue.address,
                city: loaded?.location?.city ?? issue.city,
                latitude: loaded?.location?.latitude,
                longitude: loaded?.location?.longitude,
                priority: issue.priority,
                status: issue.status,
              ),
              _Section(
                title: 'Location Details',
                icon: Icons.location_on_outlined,
                child: _locationBody(issue, loaded?.location, loading),
              ),
              _Section(
                title: 'Responsible Department',
                icon: Icons.apartment,
                child: loaded?.department == null
                    ? const Text('Not assigned yet')
                    : ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(loaded!.department!.name),
                        subtitle: const Text(
                          'View department overview and contact details',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DepartmentInformationScreen(
                              departmentId: loaded.department!.id,
                            ),
                          ),
                        ),
                      ),
              ),
              _Section(
                title: 'AI Analysis Summary',
                icon: Icons.auto_awesome,
                child: Text(
                  loaded?.aiAnalysis?.explanation?.trim().isNotEmpty == true
                      ? loaded!.aiAnalysis!.explanation!
                      : 'Automatically triaged by Smart City AI.',
                ),
              ),
              _Section(
                title: 'Evidence Photos',
                icon: Icons.photo_library_outlined,
                child: (loaded?.attachments.isEmpty ?? true)
                    ? const Text('No evidence photos attached.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final photo in loaded!.attachments)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    photo.fileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      height: 170,
                                      width: double.infinity,
                                      child: Image.network(
                                        photo.fileUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                          child: Text(
                                            'Photo preview unavailable',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              _Section(
                title: 'Status Timeline',
                icon: Icons.timeline,
                child: _timelineBody(loaded, loading),
              ),
              _Section(
                title: 'Dates',
                icon: Icons.schedule,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reported: ${formatDateTime(issue.createdAt)}'),
                    const SizedBox(height: 4),
                    Text('Last updated: ${formatDateTime(issue.updatedAt)}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationBody(
    SafetyIssue issue,
    SafetyLocation? location,
    bool loading,
  ) {
    final address = location?.address ?? issue.address;
    final city = location?.city ?? issue.city;
    if (address == null && city == null && location == null) {
      return loading ? const _Spinner() : const Text('No location recorded.');
    }
    final line = [address, city].whereType<String>().join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (line.isNotEmpty)
          Text(line, style: const TextStyle(color: AppColors.text)),
        if (location != null) ...[
          const SizedBox(height: 4),
          Text(
            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _timelineBody(SafetyIssueDetail? detail, bool loading) {
    if (detail == null) {
      return loading ? const _Spinner() : const Text('Timeline unavailable.');
    }
    if (detail.history.isEmpty) return const Text('No status updates yet.');

    final entries = detail.history;
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineTile(
            entry: entries[i],
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final StatusHistoryEntry entry;
  final bool isLast;

  const _TimelineTile({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(entry.newStatus);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: isLast ? color : AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusLabel(entry.newStatus),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isLast ? color : AppColors.text,
                    ),
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.note!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(entry.createdAt),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
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

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
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
            const Divider(height: 22),
            child,
          ],
        ),
      ),
    );
  }
}
