import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../models/department_model.dart';
import '../services/traffic_service.dart';
import '../widgets/traffic_issue_card.dart';
import 'traffic_problem_details_screen.dart';

class DepartmentInformationScreen extends StatefulWidget {
  final int? departmentId;
  final TrafficService? service;

  const DepartmentInformationScreen({super.key, this.departmentId, this.service});

  @override
  State<DepartmentInformationScreen> createState() => _DepartmentInformationScreenState();
}

class _DepartmentInformationScreenState extends State<DepartmentInformationScreen> {
  late final TrafficService _service;
  late final bool _ownsService;
  final TextEditingController _searchController = TextEditingController();
  late Future<DepartmentPage> _departments;
  Future<DepartmentInfo>? _department;
  Future<DepartmentTrafficPage>? _reports;
  int _directoryOffset = 0;
  int _reportOffset = 0;
  static const int _directoryLimit = 20;
  static const int _reportLimit = 10;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? TrafficService();
    _departments = widget.departmentId == null
        ? _service.getDepartments()
        : Future.value(const DepartmentPage(items: [], total: 0, limit: 20, offset: 0));
    if (widget.departmentId != null) {
      _department = _service.getDepartment(widget.departmentId!);
      _reports = _service.getDepartmentIssues(widget.departmentId!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  void _reloadDirectory({bool resetPage = false}) {
    setState(() {
      if (resetPage) _directoryOffset = 0;
      _departments = _service.getDepartments(
        search: _searchController.text,
        offset: _directoryOffset,
        limit: _directoryLimit,
      );
    });
  }

  void _reloadDetails() {
    if (widget.departmentId == null) return;
    setState(() {
      _department = _service.getDepartment(widget.departmentId!);
      _reports = _service.getDepartmentIssues(widget.departmentId!,
          offset: _reportOffset, limit: _reportLimit);
    });
  }

  void _changeReportPage(int offset) {
    if (widget.departmentId == null) return;
    setState(() {
      _reportOffset = offset;
      _reports = _service.getDepartmentIssues(widget.departmentId!,
          limit: _reportLimit, offset: offset);
    });
  }

  void _openDepartment(int id) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DepartmentInformationScreen(departmentId: id, service: _service),
        ),
      );

  void _openIssue(int id) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TrafficProblemDetailsScreen(issueId: id, service: _service),
        ),
      );

  Future<void> _copyContact(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.departmentId == null ? 'Departments' : 'Department Information'),
          actions: [
            IconButton(
              tooltip: 'Refresh', icon: const Icon(Icons.refresh),
              onPressed: widget.departmentId == null ? _reloadDirectory : _reloadDetails,
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 750),
              child: widget.departmentId == null ? _directoryView() : _detailsView(),
            ),
          ),
        ),
      );

  Widget _directoryView() => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('City Departments',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 5),
            const Text('Find responsible departments and their traffic reports.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            TextField(
              key: const Key('department-search'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _reloadDirectory(resetPage: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search departments...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear department search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        _reloadDirectory(resetPage: true);
                      },
                    ),
                  IconButton(
                    tooltip: 'Search departments',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _reloadDirectory(resetPage: true),
                  ),
                ]),
              ),
            ),
          ]),
        ),
        Expanded(child: FutureBuilder<DepartmentPage>(
          future: _departments,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _errorView(snapshot.error.toString(), () => _reloadDirectory());
            }
            final page = snapshot.data!;
            if (page.items.isEmpty) {
              return _emptyView('No departments found',
                  'Try another search or ask the administrator to add a department.');
            }
            return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), children: [
              Text('${page.total} departments',
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              for (final dept in page.items)
                Card(child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightBlue,
                    child: Icon(Icons.apartment, color: AppColors.primaryDark),
                  ),
                  title: Text(dept.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${dept.trafficIssueCount} traffic reports\n${dept.description?.trim().isNotEmpty == true ? dept.description! : 'Description not provided'}',
                    maxLines: 3, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openDepartment(dept.id),
                )),
              _pagination(
                page.offset, page.limit, page.total,
                previous: () { _directoryOffset -= _directoryLimit; _reloadDirectory(); },
                next: () { _directoryOffset += _directoryLimit; _reloadDirectory(); },
              ),
            ]);
          },
        )),
      ]);

  Widget _detailsView() => FutureBuilder<DepartmentInfo>(
        future: _department,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorView(snapshot.error.toString(), _reloadDetails);
          }
          final d = snapshot.data!;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.apartment_rounded, color: Colors.white, size: 34),
                const SizedBox(height: 9),
                Text(d.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 12),
                Chip(
                  avatar: const Icon(Icons.traffic, color: AppColors.primaryDark, size: 18),
                  label: Text('${d.trafficIssueCount} active traffic reports'),
                  backgroundColor: AppColors.card,
                  side: BorderSide.none,
                ),
              ]),
            ),
            const SizedBox(height: 10),
            _section('Department Overview', Icons.info_outline,
                Text(_present(d.description))),
            _section('Responsibilities', Icons.assignment_outlined,
                Text(_present(d.responsibilities))),
            _section('Contact Information', Icons.contact_phone_outlined,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _infoRow(Icons.email_outlined, 'Email', d.contactEmail),
                  _infoRow(Icons.call_outlined, 'Phone', d.contactPhone),
                ])),
            _section('Office Location', Icons.location_on_outlined,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_present(d.officeAddress)),
                  if (d.officeCity?.trim().isNotEmpty == true)
                    Text('City: ${d.officeCity}'),
                  if (d.hasValidCoordinates) ...[
                    const SizedBox(height: 9),
                    Text('Coordinates: ${d.officeLatitude}, ${d.officeLongitude}',
                        style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(initialCenter: LatLng(d.officeLatitude!, d.officeLongitude!),
                                              initialZoom: 14),
                          children: [
                            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'lk.smartcity.ai_platform'),
                            MarkerLayer(markers: [Marker(
                              point: LatLng(d.officeLatitude!, d.officeLongitude!),
                              width: 44, height: 44,
                              child: const Icon(Icons.location_pin, color: AppColors.error, size: 42),
                            )]),
                            const SimpleAttributionWidget(source: Text('© OpenStreetMap contributors')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ])),
            _section('Operating Hours', Icons.access_time,
                Text(_present(d.operatingHours))),
            _section('Department Traffic Reports', Icons.traffic,
                FutureBuilder<DepartmentTrafficPage>(
                  future: _reports,
                  builder: (context, reportSnapshot) {
                    if (reportSnapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (reportSnapshot.hasError) {
                      return Column(children: [
                        Text(reportSnapshot.error.toString()),
                        TextButton(onPressed: _reloadDetails, child: const Text('Try again')),
                      ]);
                    }
                    final page = reportSnapshot.data!;
                    if (page.items.isEmpty) {
                      return const Text('No active traffic reports assigned to this department.');
                    }
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${page.total} traffic reports',
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 8),
                      for (final issue in page.items)
                        TrafficIssueCard(issue: issue, onTap: () => _openIssue(issue.id)),
                      _pagination(page.offset, page.limit, page.total,
                        previous: () => _changeReportPage(page.offset - _reportLimit),
                        next: () => _changeReportPage(page.offset + _reportLimit)),
                    ]);
                  },
                )),
          ]);
        },
      );

  Widget _section(String title, IconData icon, Widget body) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 9),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            ]),
            const Divider(height: 23),
            body,
          ]),
        ),
      );

  String _present(String? value) => value?.trim().isNotEmpty == true ? value! : 'Not provided';

  Widget _infoRow(IconData icon, String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Icon(icon, size: 19, color: AppColors.muted),
          const SizedBox(width: 9),
          Expanded(child: SelectableText('$label: ${_present(value)}')),
          if (value?.trim().isNotEmpty == true)
            IconButton(
              tooltip: 'Copy $label',
              icon: const Icon(Icons.copy_outlined, size: 19),
              color: AppColors.primary,
              onPressed: () => _copyContact(label, value!),
            ),
        ]),
      );

  Widget _pagination(int offset, int limit, int total,
      {required VoidCallback previous, required VoidCallback next}) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton(onPressed: offset > 0 ? previous : null,
              child: const Text('Previous')),
          Text('${offset + 1}–${(offset + limit < total ? offset + limit : total)} of $total',
              style: const TextStyle(color: AppColors.muted)),
          TextButton(onPressed: offset + limit < total ? next : null,
              child: const Text('Next')),
        ]),
      );

  Widget _errorView(String message, VoidCallback retry) => Center(
        child: Padding(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: retry, child: const Text('Try again')),
          ]),
        ),
      );

  Widget _emptyView(String title, String subtitle) => Center(
        child: Padding(padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.apartment_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ]),
        ),
      );
}
