import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/traffic_issue_model.dart';
import '../services/traffic_service.dart';
import '../widgets/traffic_status_timeline.dart';
import 'department_information_screen.dart';

class TrafficProblemDetailsScreen extends StatefulWidget {
  final int issueId;
  final TrafficService? service;

  const TrafficProblemDetailsScreen({super.key, required this.issueId, this.service});

  @override
  State<TrafficProblemDetailsScreen> createState() => _TrafficProblemDetailsScreenState();
}

class _TrafficProblemDetailsScreenState extends State<TrafficProblemDetailsScreen> {
  late final TrafficService _service;
  late final bool _ownsService;
  late Future<TrafficIssueDetail> _future;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? TrafficService();
    _future = _service.getIssue(widget.issueId);
  }

  @override
  void dispose() {
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  void _retry() => setState(() => _future = _service.getIssue(widget.issueId));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Traffic Problem Details')),
        body: FutureBuilder<TrafficIssueDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 44, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _retry, child: const Text('Try again')),
                ]),
              ));
            }
            final detail = snapshot.data!;
            final issue = detail.issue;
            return Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 750),
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Card(child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(issue.title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Wrap(spacing: 9, runSpacing: 8, children: [
                      Chip(label: Text('Priority: ${trafficLabel(issue.priority)}')),
                      Chip(label: Text('Status: ${trafficLabel(issue.status)}')),
                    ]),
                    const SizedBox(height: 8),
                    Text('Report #${issue.id}  •  ${trafficDate(issue.createdAt)}',
                        style: const TextStyle(color: AppColors.muted)),
                  ]),
                )),
                _SectionCard(title: 'Problem Description', icon: Icons.description_outlined,
                    child: Text(issue.description)),
                _SectionCard(title: 'Location Details', icon: Icons.location_on_outlined,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(issue.location?.address ?? 'Address not provided'),
                      if (issue.location?.city != null) Text('City: ${issue.location!.city!}'),
                      if (issue.location != null) SelectableText(
                        'Coordinates: ${issue.location!.latitude}, ${issue.location!.longitude}',
                      ),
                    ])),
                _SectionCard(title: 'Responsible Department', icon: Icons.apartment,
                    child: issue.departmentId == null
                        ? const Text('Not assigned yet')
                        : ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(issue.departmentName ?? 'View assigned department'),
                            subtitle: const Text('View department overview and contact details'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DepartmentInformationScreen(
                                  departmentId: issue.departmentId!, service: _service),
                              ),
                            ),
                          )),
                if (detail.aiSummary != null && detail.aiSummary!.trim().isNotEmpty)
                  _SectionCard(title: 'AI Analysis Summary', icon: Icons.auto_awesome,
                      child: Text(detail.aiSummary!)),
                _SectionCard(title: 'Evidence Photos', icon: Icons.photo_library_outlined,
                    child: detail.photos.isEmpty
                        ? const Text('No evidence photos attached.')
                        : Column(children: detail.photos.map((photo) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(photo.fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              // Only show trusted image URLs. This is a read-only view.
                              if (Uri.tryParse(photo.fileUrl)?.hasScheme == true &&
                                  ['https', 'http'].contains(Uri.tryParse(photo.fileUrl)!.scheme))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(photo.fileUrl,
                                    height: 150, width: double.infinity, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Text('Photo could not be loaded.')),
                                )
                              else
                                const Text('Photo preview is unavailable for this file URL.'),
                            ]),
                          )).toList()),
                ),
                _SectionCard(title: 'Status Timeline', icon: Icons.timeline,
                    child: TrafficStatusTimeline(history: detail.statusHistory)),
                if (detail.similarIssues.isNotEmpty)
                  _SectionCard(title: 'Similar Traffic Reports', icon: Icons.compare_arrows,
                      child: Column(children: [
                        for (final item in detail.similarIssues)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.title),
                            subtitle: Text('${trafficLabel(item.status)} • ${trafficDate(item.createdAt)}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => TrafficProblemDetailsScreen(issueId: item.id, service: _service),
                            )),
                          ),
                      ])),
              ]),
            ));
          },
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            ]),
            const Divider(height: 22),
            child,
          ]),
        ),
      );
}
