import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/safety_issue_model.dart';
import '../providers/complaint_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/officer_management_panel.dart';
import '../widgets/safety_alert_card.dart'; // SeverityBadge
import '../widgets/safety_issue_card.dart'; // status helpers

/// Everything about one complaint: description, photos, location, AI analysis,
/// responsible department, status timeline and related complaints.
/// Officers also get the management panel at the bottom.
class ComplaintDetailsScreen extends StatefulWidget {
  /// The complaint tapped in the list. Shown immediately while the full details load.
  final SafetyIssue issue;

  /// Show the officer tools. TODO: read from Member 1's logged-in user.
  final bool isOfficer;

  const ComplaintDetailsScreen({
    super.key,
    required this.issue,
    this.isOfficer = true,
  });

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ComplaintProvider>().loadDetail(widget.issue.id);
    });
  }

  Future<void> _openRelated(SafetyIssue related) async {
    final provider = context.read<ComplaintProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: ComplaintDetailsScreen(issue: related, isOfficer: widget.isOfficer),
        ),
      ),
    );
    // The provider holds one detail at a time, so reload this complaint when we come back.
    if (mounted) provider.loadDetail(widget.issue.id);
  }

  void _showPhoto(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(40),
              child: Icon(Icons.broken_image_outlined, size: 48, color: AppColors.muted),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ComplaintProvider>();
    final detail = p.detail;
    final loaded = (detail != null && detail.issue.id == widget.issue.id) ? detail : null;
    final issue = loaded?.issue ?? widget.issue;
    final loading = p.isLoadingDetail && loaded == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(issue.reference),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
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
              _header(issue),
              _latestUpdate(loaded),
              _Section(
                title: 'Description',
                icon: Icons.description_outlined,
                child: Text(
                  issue.description,
                  style: const TextStyle(color: AppColors.text, height: 1.4),
                ),
              ),
              _Section(
                title: 'Photos',
                icon: Icons.photo_library_outlined,
                child: _photos(loaded, loading),
              ),
              _Section(
                title: 'Location',
                icon: Icons.location_on_outlined,
                child: _location(issue, loaded?.location, loading),
              ),
              _Section(
                title: 'AI analysis',
                icon: Icons.auto_awesome_outlined,
                child: _aiAnalysis(loaded, loading),
              ),
              _Section(
                title: 'Responsible department',
                icon: Icons.apartment_outlined,
                child: _department(loaded, loading),
              ),
              _Section(
                title: 'Status timeline',
                icon: Icons.timeline,
                child: _timeline(loaded, loading),
              ),
              _Section(
                title: 'Related complaints',
                icon: Icons.link,
                child: _related(loaded, loading),
              ),
              if (widget.isOfficer && loaded != null)
                OfficerManagementPanel(detail: loaded),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- sections ----------------

  Widget _header(SafetyIssue issue) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SafetyStatusChip(status: issue.status),
                const SizedBox(width: 12),
                SeverityBadge(severity: issue.priority),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              issue.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reported on ${formatDateTime(issue.createdAt)}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  /// The newest timeline entry that carries a message from the officers.
  Widget _latestUpdate(SafetyIssueDetail? detail) {
    if (detail == null) return const SizedBox.shrink();
    StatusHistoryEntry? latest;
    for (final entry in detail.history.reversed) {
      if (entry.note != null && entry.note!.trim().isNotEmpty) {
        latest = entry;
        break;
      }
    }
    if (latest == null) return const SizedBox.shrink();

    return _Section(
      title: 'Latest update',
      icon: Icons.campaign_outlined,
      accent: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            latest.note!,
            style: const TextStyle(color: AppColors.text, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            formatDateTime(latest.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _photos(SafetyIssueDetail? detail, bool loading) {
    if (detail == null) {
      return loading ? const _Spinner() : const Text('Photos unavailable.');
    }
    final images = detail.attachments.where((a) => a.isImage).toList();
    final others = detail.attachments.where((a) => !a.isImage).toList();
    if (images.isEmpty && others.isEmpty) return const Text('No photos attached.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final url = images[index].fileUrl;
                return GestureDetector(
                  onTap: () => _showPhoto(url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 160,
                          height: 120,
                          color: AppColors.border,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: 160,
                        height: 120,
                        color: AppColors.border,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final file in others)
                Chip(
                  avatar: const Icon(Icons.attach_file, size: 16),
                  label: Text(file.fileName),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _location(SafetyIssue issue, SafetyLocation? location, bool loading) {
    final address = location?.address ?? issue.address;
    final city = location?.city ?? issue.city;
    if (address == null && city == null && location == null) {
      return loading ? const _Spinner() : const Text('No location recorded.');
    }
    final line = [address, city].whereType<String>().join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (line.isNotEmpty) Text(line, style: const TextStyle(color: AppColors.text)),
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

  Widget _aiAnalysis(SafetyIssueDetail? detail, bool loading) {
    if (detail == null) {
      return loading ? const _Spinner() : const Text('AI analysis unavailable.');
    }
    final ai = detail.aiAnalysis;
    if (ai == null) return const Text('No AI analysis available yet.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Recommended priority: ',
                style: TextStyle(color: AppColors.muted)),
            if (ai.recommendedPriority != null)
              SeverityBadge(severity: ai.recommendedPriority!)
            else
              const Text('-'),
          ],
        ),
        if (ai.confidenceScore != null) ...[
          const SizedBox(height: 6),
          Text(
            'Confidence: ${ai.confidenceScore}%',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
        if (ai.explanation != null && ai.explanation!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            ai.explanation!,
            style: const TextStyle(color: AppColors.text, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _department(SafetyIssueDetail? detail, bool loading) {
    if (detail == null) {
      return loading ? const _Spinner() : const Text('Department unavailable.');
    }
    final dept = detail.department;
    final a = detail.assignment;
    if (dept == null && a == null) {
      return const Text('Not assigned to a department yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dept?.name ?? a?.departmentName ?? 'Department #${a?.departmentId}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        if (a != null) ...[
          const SizedBox(height: 6),
          Text(
            'Officer: ${a.assignedToName ?? 'Officer #${a.assignedTo}'}',
            style: const TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 2),
          Text(
            'Assigned ${formatDateTime(a.assignedAt)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _timeline(SafetyIssueDetail? detail, bool loading) {
    if (detail == null) {
      return loading ? const _Spinner() : const Text('Timeline unavailable.');
    }
    if (detail.history.isEmpty) return const Text('No status updates yet.');

    final entries = detail.history;
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineTile(entry: entries[i], isLast: i == entries.length - 1),
      ],
    );
  }

  Widget _related(SafetyIssueDetail? detail, bool loading) {
    if (detail == null) {
      return loading ? const _Spinner() : const Text('Related complaints unavailable.');
    }
    if (detail.related.isEmpty) return const Text('No related complaints found.');

    return Column(
      children: [
        for (var i = 0; i < detail.related.length; i++) ...[
          InkWell(
            onTap: () => _openRelated(detail.related[i]),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.related[i].reference,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail.related[i].title,
                          style: const TextStyle(color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        SafetyStatusChip(status: detail.related[i].status),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ),
          if (i < detail.related.length - 1) const Divider(height: 1),
        ],
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
  final bool isLast; // the most recent step is highlighted

  const _TimelineTile({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(entry.newStatus);
    final title = entry.isPlainUpdate ? 'Update' : statusLabel(entry.newStatus);
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
                  Expanded(child: Container(width: 2, color: AppColors.border)),
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
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isLast ? color : AppColors.text,
                    ),
                  ),
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.note!,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(entry.createdAt),
                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
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
