import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_city_app/core/config/app_config.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:smart_city_app/features/reporting/widgets/issue_location_tracker_card.dart';
import 'package:smart_city_app/features/traffic/screens/department_information_screen.dart';
import 'package:smart_city_app/features/traffic/screens/traffic_status_management_screen.dart';

class WasteProblemDetailsScreen extends StatefulWidget {
  final Map<String, String> issue;

  const WasteProblemDetailsScreen({super.key, required this.issue});

  @override
  State<WasteProblemDetailsScreen> createState() =>
      _WasteProblemDetailsScreenState();
}

class _WasteProblemDetailsScreenState extends State<WasteProblemDetailsScreen> {
  Map<String, dynamic>? _liveIssue;
  Map<String, dynamic>? _aiAnalysis;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveDetails();
  }

  int? get _parsedIssueId {
    final rawId = (_liveIssue?['id'] ?? widget.issue['id'] ?? '').toString();
    return int.tryParse(rawId.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  Future<void> _loadLiveDetails() async {
    final issueId = _parsedIssueId;
    if (issueId == null || issueId <= 0) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final issueRes = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/issues/$issueId'))
          .timeout(AppConfig.requestTimeout);
      if (issueRes.statusCode == 200) {
        _liveIssue = jsonDecode(issueRes.body) as Map<String, dynamic>;
      }

      final aiRes = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/ai/issues/$issueId/analysis'))
          .timeout(AppConfig.requestTimeout);
      if (aiRes.statusCode == 200) {
        _aiAnalysis = jsonDecode(aiRes.body) as Map<String, dynamic>;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _formatLabel(String raw) {
    final clean = raw.replaceAll('_', ' ').trim();
    if (clean.isEmpty) return '';
    return clean
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final issueId = _parsedIssueId;
    final idText = (_liveIssue?['id'] ?? widget.issue['id'] ?? 'N/A').toString();
    final titleText =
        (_liveIssue?['title'] ?? widget.issue['title'] ?? 'Waste issue')
            .toString();
    final rawStatus =
        (_liveIssue?['status'] ?? widget.issue['status'] ?? 'reported')
            .toString();
    final statusText = _formatLabel(rawStatus);
    final rawPriority =
        (_liveIssue?['priority'] ?? widget.issue['priority'] ?? 'medium')
            .toString();
    final priorityText = _formatLabel(rawPriority);
    final descriptionText =
        (_liveIssue?['description'] ??
                widget.issue['description'] ??
                'No description provided.')
            .toString();

    final createdAtStr = (_liveIssue?['created_at'] ?? widget.issue['date'] ?? '')
        .toString();
    final dateLabel = createdAtStr.length >= 10
        ? createdAtStr.substring(0, 10)
        : createdAtStr;

    String locationText = widget.issue['location'] ?? 'Not available';
    String? locAddress;
    String? locCity;
    double? locLat;
    double? locLon;
    final singleLoc = _liveIssue?['location'];
    final locs = _liveIssue?['locations'] as List<dynamic>?;
    if (singleLoc is Map) {
      final firstLoc = Map<String, dynamic>.from(singleLoc);
      locAddress = firstLoc['address']?.toString();
      locCity = firstLoc['city']?.toString();
      locLat = (firstLoc['latitude'] as num?)?.toDouble();
      locLon = (firstLoc['longitude'] as num?)?.toDouble();
    } else if (locs != null && locs.isNotEmpty && locs.first is Map) {
      final firstLoc = Map<String, dynamic>.from(locs.first as Map);
      locAddress = firstLoc['address']?.toString();
      locCity = firstLoc['city']?.toString();
      locLat = (firstLoc['latitude'] as num?)?.toDouble();
      locLon = (firstLoc['longitude'] as num?)?.toDouble();
    }
    final parts = [
      locAddress,
      locCity,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) {
      locationText = parts.join(', ');
    } else if (locationText != 'Not available') {
      locCity = locationText;
    }

    final deptObj = _liveIssue?['department'];
    int? deptId;
    String? deptName;
    if (deptObj is Map) {
      deptId = deptObj['id'] as int?;
      deptName = deptObj['name']?.toString();
    }

    final attachments = _liveIssue?['attachments'] as List<dynamic>? ?? [];
    final statusTimeline =
        _liveIssue?['status_timeline'] as List<dynamic>? ?? [];
    final similarReports =
        _liveIssue?['similar_reports'] as List<dynamic>? ?? [];

    String aiSummary = _aiAnalysis?['summary']?.toString() ??
        _aiAnalysis?['explanation']?.toString() ??
        '';
    if (aiSummary.isEmpty) {
      final liveAiList = _liveIssue?['ai_analysis'] as List<dynamic>? ?? [];
      if (liveAiList.isNotEmpty && liveAiList.first is Map) {
        aiSummary =
            (liveAiList.first['explanation'] ?? liveAiList.first['summary'] ?? '')
                .toString();
      }
    }
    if (aiSummary.isEmpty) {
      aiSummary = 'Automatically analyzed by Smart City AI.';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Waste Problem Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadLiveDetails,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              // Traffic-style Header Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 9,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('Priority: $priorityText')),
                          Chip(label: Text('Status: $statusText')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Report #$idText${dateLabel.isNotEmpty ? "  •  $dateLabel" : ""}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              if (issueId != null && issueId > 0)
                StaffCaseManagementBanner(
                  issueId: issueId,
                  categoryLabel: 'Waste',
                  currentStatus: rawStatus,
                  currentPriority: rawPriority,
                  onUpdated: _loadLiveDetails,
                ),
              _sectionCard(
                title: 'Problem Description',
                icon: Icons.description_outlined,
                child: Text(descriptionText),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: IssueLocationTrackerCard(
                  title: titleText,
                  category: 'waste',
                  address: locAddress ?? locationText,
                  city: locCity,
                  latitude: locLat,
                  longitude: locLon,
                  priority: rawPriority,
                  status: rawStatus,
                ),
              ),
              _sectionCard(
                title: 'Location Details',
                icon: Icons.location_on_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locAddress ?? locationText),
                    if (locCity != null && locCity.isNotEmpty)
                      Text('City: $locCity'),
                    if (locLat != null && locLon != null)
                      SelectableText('Coordinates: $locLat, $locLon'),
                  ],
                ),
              ),
              _sectionCard(
                title: 'Responsible Department',
                icon: Icons.apartment,
                child: deptId == null
                    ? const Text('Not assigned yet')
                    : ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(deptName ?? 'View assigned department'),
                        subtitle: const Text(
                          'View department overview and contact details',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DepartmentInformationScreen(
                              departmentId: deptId!,
                            ),
                          ),
                        ),
                      ),
              ),
              _sectionCard(
                title: 'AI Analysis Summary',
                icon: Icons.auto_awesome,
                child: Text(aiSummary),
              ),
              _sectionCard(
                title: 'Evidence Photos',
                icon: Icons.photo_library_outlined,
                child: attachments.isEmpty
                    ? const Text('No evidence photos attached.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final raw in attachments)
                            if (raw is Map)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 7,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (raw['file_name'] ?? 'Evidence photo')
                                          .toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        height: 170,
                                        width: double.infinity,
                                        child: Image.network(
                                          (raw['file_url'] ?? '').toString(),
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
              _sectionCard(
                title: 'Status Timeline',
                icon: Icons.timeline,
                child: statusTimeline.isEmpty
                    ? const Text('No status updates recorded yet.')
                    : Column(
                        children: [
                          for (final item in statusTimeline)
                            if (item is Map)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                title: Text(
                                  _formatLabel(
                                    (item['new_status'] ?? 'reported')
                                        .toString(),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item['note'] != null &&
                                        item['note']
                                            .toString()
                                            .trim()
                                            .isNotEmpty)
                                      Text(item['note'].toString()),
                                    if (item['created_at'] != null)
                                      Text(
                                        item['created_at']
                                            .toString()
                                            .replaceFirst('T', ' ')
                                            .substring(
                                              0,
                                              item['created_at']
                                                          .toString()
                                                          .length >=
                                                      16
                                                  ? 16
                                                  : item['created_at']
                                                      .toString()
                                                      .length,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                        ],
                      ),
              ),
              _sectionCard(
                title: 'Similar Waste Reports',
                icon: Icons.compare_arrows,
                child: similarReports.isEmpty
                    ? const Text('No similar waste reports found.')
                    : Column(
                        children: [
                          for (final item in similarReports)
                            if (item is Map)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  (item['title'] ?? 'Waste Report').toString(),
                                ),
                                subtitle: Text(
                                  '${_formatLabel((item['status'] ?? '').toString())} • ${_formatLabel((item['priority'] ?? '').toString())} Priority',
                                ),
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
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
