import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../traffic/screens/department_information_screen.dart';
import '../../traffic/screens/traffic_status_management_screen.dart';
import '../widgets/issue_location_tracker_card.dart';

class ReportDetailsScreen extends StatefulWidget {
  final int issueId;
  final Map<String, dynamic>? initialData;

  const ReportDetailsScreen({
    super.key,
    required this.issueId,
    this.initialData,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  Map<String, dynamic>? _issue;
  Map<String, dynamic>? _aiAnalysis;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _issue = widget.initialData;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final issueUri = Uri.parse(
        '${AppConfig.apiBaseUrl}/issues/${widget.issueId}',
      );
      final res = await http.get(issueUri).timeout(AppConfig.requestTimeout);
      if (res.statusCode == 200) {
        _issue = jsonDecode(res.body) as Map<String, dynamic>;
      }

      try {
        final aiUri = Uri.parse(
          '${AppConfig.apiBaseUrl}/ai/issues/${widget.issueId}/analysis',
        );
        final aiRes = await http.get(aiUri).timeout(AppConfig.requestTimeout);
        if (aiRes.statusCode == 200) {
          _aiAnalysis = jsonDecode(aiRes.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    } catch (e) {
      if (_issue == null) {
        _error = e.toString();
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('resolved')) return AppColors.success;
    if (s.contains('progress') || s.contains('assigned')) {
      return AppColors.warning;
    }
    if (s.contains('rejected')) return AppColors.error;
    return AppColors.primary;
  }

  Color _priorityColor(String priority) {
    final p = priority.toLowerCase();
    if (p == 'critical' || p == 'high') return AppColors.error;
    if (p == 'medium') return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final data = _issue;
    String? address;
    String? city;
    double? lat;
    double? lon;
    if (data != null) {
      final locObj = data['location'];
      final locsList = data['locations'];
      if (locObj is Map) {
        address = locObj['address']?.toString();
        city = locObj['city']?.toString();
        lat = (locObj['latitude'] as num?)?.toDouble();
        lon = (locObj['longitude'] as num?)?.toDouble();
      } else if (locsList is List &&
          locsList.isNotEmpty &&
          locsList.first is Map) {
        final first = Map<String, dynamic>.from(locsList.first as Map);
        address = first['address']?.toString();
        city = first['city']?.toString();
        lat = (first['latitude'] as num?)?.toDouble();
        lon = (first['longitude'] as num?)?.toDouble();
      } else {
        address = data['address']?.toString();
        city = data['city']?.toString();
        lat = (data['latitude'] as num?)?.toDouble();
        lon = (data['longitude'] as num?)?.toDouble();
      }
    }

    final categoryStr = _formatLabel(
      (data?['category'] ?? 'City').toString(),
    );
    final deptObj = data?['department'];
    int? deptId;
    String? deptName;
    if (deptObj is Map) {
      deptId = deptObj['id'] as int?;
      deptName = deptObj['name']?.toString();
    }
    final attachments = data?['attachments'] as List<dynamic>? ?? [];
    final statusTimeline = data?['status_timeline'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$categoryStr Problem Details • #${widget.issueId}'),
        actions: [
          IconButton(
            onPressed: _loadDetails,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading && data == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && data == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _badge(
                                        (data?['category'] ?? 'general')
                                            .toString()
                                            .toUpperCase(),
                                        AppColors.categoryColor(
                                          (data?['category'] ?? 'general')
                                              .toString(),
                                        ),
                                      ),
                                      _badge(
                                        (data?['status'] ?? 'reported')
                                            .toString()
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                        _statusColor(
                                          (data?['status'] ?? '').toString(),
                                        ),
                                      ),
                                      _badge(
                                        'PRIORITY: ${(data?['priority'] ?? 'medium').toString().toUpperCase()}',
                                        _priorityColor(
                                          (data?['priority'] ?? '').toString(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    (data?['title'] ?? 'City Report')
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    (data?['description'] ??
                                            'No detailed description provided.')
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.text,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          StaffCaseManagementBanner(
                            issueId: widget.issueId,
                            categoryLabel: categoryStr,
                            currentStatus: data?['status']?.toString(),
                            currentPriority: data?['priority']?.toString(),
                            onUpdated: _loadDetails,
                          ),
                          IssueLocationTrackerCard(
                            title: (data?['title'] ?? 'City Report').toString(),
                            category: (data?['category'] ?? 'all').toString(),
                            address: address,
                            city: city,
                            latitude: lat,
                            longitude: lon,
                            priority: data?['priority']?.toString(),
                            status: data?['status']?.toString(),
                          ),
                          const SizedBox(height: 14),
                          _sectionCard(
                            title: 'Responsible Department',
                            icon: Icons.apartment,
                            child: deptId == null
                                ? const Text('Not assigned yet')
                                : ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      deptName ?? 'View assigned department',
                                    ),
                                    subtitle: const Text(
                                      'View department overview and contact details',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            DepartmentInformationScreen(
                                              departmentId: deptId!,
                                            ),
                                      ),
                                    ),
                                  ),
                          ),
                          if (_aiAnalysis != null)
                            _sectionCard(
                              title: 'AI Triage & Priority Analysis',
                              icon: Icons.auto_awesome_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recommended Priority: ${(_aiAnalysis!['recommended_priority'] ?? _aiAnalysis!['priority'] ?? 'Medium').toString().toUpperCase()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  if (_aiAnalysis!['summary'] != null ||
                                      _aiAnalysis!['explanation'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      (_aiAnalysis!['summary'] ??
                                              _aiAnalysis!['explanation'])
                                          .toString(),
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          _sectionCard(
                            title: 'Evidence Photos',
                            icon: Icons.photo_library_outlined,
                            child: attachments.isEmpty
                                ? const Text('No evidence photos attached.')
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final raw in attachments)
                                        if (raw is Map)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (raw['file_name'] ??
                                                          'Evidence photo')
                                                      .toString(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: SizedBox(
                                                    height: 170,
                                                    width: double.infinity,
                                                    child: Image.network(
                                                      (raw['file_url'] ?? '')
                                                          .toString(),
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) =>
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
                                                (item['new_status'] ??
                                                        'reported')
                                                    .toString(),
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                        ],
                      ),
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
      margin: const EdgeInsets.only(bottom: 14),
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

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
