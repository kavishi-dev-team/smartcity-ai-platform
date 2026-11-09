import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../reporting/widgets/issue_location_tracker_card.dart';
import '../models/traffic_issue_model.dart';
import '../services/traffic_service.dart';
import '../widgets/traffic_status_timeline.dart';
import '../widgets/traffic_photo_viewer.dart';
import 'traffic_incident_map_screen.dart';
import 'department_information_screen.dart';
import 'traffic_status_management_screen.dart';

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

  void _retry() {
  if (!mounted) return;

  final nextFuture = _service.getIssue(widget.issueId);

  setState(() {
    _future = nextFuture;
  });
}
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
                // Officer / Manager / Super Admin entry point.
                StaffCaseManagementBanner(
                  issueId: issue.id,
                  categoryLabel: 'Traffic',
                  currentStatus: issue.status,
                  currentPriority: issue.priority,
                  service: _service,
                  onUpdated: () {
                    if (mounted) _retry();
                  },
                ),
                _SectionCard(title: 'Problem Description', icon: Icons.description_outlined,
                    child: Text(issue.description)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: IssueLocationTrackerCard(
                    title: issue.title,
                    category: 'traffic',
                    address: issue.location?.address,
                    city: issue.location?.city,
                    latitude: issue.location?.latitude,
                    longitude: issue.location?.longitude,
                    priority: issue.priority,
                    status: issue.status,
                  ),
                ),
                _SectionCard(title: 'Location Details', icon: Icons.location_on_outlined,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(issue.location?.address ?? 'Address not provided'),
                      if (issue.location?.city != null) Text('City: ${issue.location!.city!}'),
                      if (issue.location != null) SelectableText(
                        'Coordinates: ${issue.location!.latitude}, ${issue.location!.longitude}',
                      ),
                      const SizedBox(height: 12),
                      if (issue.location?.hasValidCoordinates == true)
                        OutlinedButton.icon(
                          key: const Key('traffic-view-on-map'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TrafficIncidentMapScreen(
                                service: _service,
                                focusMarker: TrafficMapMarker(
                                  id: issue.id,
                                  title: issue.title,
                                  status: issue.status,
                                  priority: issue.priority,
                                  location: issue.location!,
                                ),
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('View on Map'),
                        )
                      else
                        const Text('Map is unavailable without valid coordinates.',
                            style: TextStyle(color: AppColors.muted)),
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
                _SectionCard(title: 'AI Analysis Summary', icon: Icons.auto_awesome,
                    child: Text(detail.aiSummary?.trim().isNotEmpty == true
                        ? detail.aiSummary!
                        : 'No AI analysis is available for this report yet.')),
                _SectionCard(title: 'Evidence Photos', icon: Icons.photo_library_outlined,
                    child: detail.photos.isEmpty
                        ? const Text('No evidence photos attached.')
                        : Column(children: [
                            for (var index = 0; index < detail.photos.length; index++)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(detail.photos[index].fileName,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Semantics(
                                      button: true,
                                      label: 'View photo ${index + 1} full screen',
                                      child: InkWell(
                                        key: Key('traffic-evidence-photo-$index'),
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(builder: (_) =>
                                              TrafficPhotoViewer(
                                                photos: detail.photos,
                                                initialIndex: index,
                                              )),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Stack(alignment: Alignment.bottomRight,
                                            children: [
                                              SizedBox(
                                                height: 170,
                                                width: double.infinity,
                                                child: Image.network(
                                                  detail.photos[index].fileUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Center(child: Text('Photo preview unavailable')),
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.all(10),
                                                child: Chip(
                                                  avatar: Icon(Icons.zoom_in, size: 18),
                                                  label: Text('View photo'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ])),
                _SectionCard(title: 'Status Timeline', icon: Icons.timeline,
                    child: TrafficStatusTimeline(history: detail.statusHistory)),
                _SectionCard(title: 'Similar Traffic Reports', icon: Icons.compare_arrows,
                    child: detail.similarIssues.isEmpty
                        ? const Text('No similar traffic reports found.')
                        : Column(children: [
                            for (final item in detail.similarIssues)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.title),
                                subtitle: Text('${trafficLabel(item.status)} • ${trafficDate(item.createdAt)}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                  builder: (_) => TrafficProblemDetailsScreen(
                                    issueId: item.id, service: _service,
                                  ),
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
