import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:smart_city_app/features/auth/providers/auth_provider.dart';
import 'package:smart_city_app/features/reporting/widgets/issue_location_tracker_card.dart';
import 'package:smart_city_app/features/reporting/widgets/quick_issue_report_sheet.dart';

import '../services/waste_service.dart';
import '../../traffic/screens/traffic_status_management_screen.dart';
import 'collection_information_screen.dart';
import 'recycling_information_screen.dart';
import 'waste_problem_details_screen.dart';

class WasteProblemsScreen extends StatefulWidget {
  const WasteProblemsScreen({super.key});

  @override
  State<WasteProblemsScreen> createState() => _WasteProblemsScreenState();
}

class _WasteProblemsScreenState extends State<WasteProblemsScreen> {
  final _service = WasteService();
  final _searchController = TextEditingController();

  List<Map<String, String>> _issues = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  String _appliedStatus = 'All';
  String _appliedPriority = 'All';
  String _appliedLocation = 'All';
  DateTimeRange? _appliedDates;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  String _displayLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Map<String, String> _mapIssue(Map<String, dynamic> item) {
    final locations = item['locations'] as List<dynamic>? ?? [];
    final cities = <String>{};
    final addresses = <String>{};

    for (final value in locations) {
      final location = Map<String, dynamic>.from(value as Map);
      final city = location['city']?.toString().trim() ?? '';
      final address = location['address']?.toString().trim() ?? '';

      if (city.isNotEmpty) cities.add(city);
      if (address.isNotEmpty) addresses.add(address);
    }

    final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');

    return {
      'id': item['id'].toString(),
      'title': item['title']?.toString() ?? 'Waste issue',
      'description': item['description']?.toString() ?? '',
      'status': _displayLabel(item['status']?.toString() ?? 'unknown'),
      'priority': _displayLabel(item['priority']?.toString() ?? 'unknown'),
      'location': cities.isNotEmpty
          ? cities.join(', ')
          : addresses.isNotEmpty
          ? addresses.join(', ')
          : 'Not available',
      'date': createdAt == null
          ? ''
          : '${createdAt.year}-'
                '${createdAt.month.toString().padLeft(2, '0')}-'
                '${createdAt.day.toString().padLeft(2, '0')}',
    };
  }

  Future<void> _loadIssues() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = context.read<AuthProvider>().user;
      final reportedBy = (user != null && user.isCitizen) ? user.id : null;

      // Fetch every page so local search and filters cover all reports.
      final loaded = <Map<String, String>>[];
      var offset = 0;

      while (true) {
        final response = await _service.getWasteIssues(
          offset: offset,
          limit: 100,
          reportedBy: reportedBy,
        );

        if (!mounted) return;

        final rawItems = response['items'];
        final total = response['total'];

        if (rawItems is! List || total is! int) {
          throw const FormatException('Invalid issue list response.');
        }

        if (rawItems.isEmpty) break;

        for (final item in rawItems) {
          loaded.add(_mapIssue(Map<String, dynamic>.from(item as Map)));
        }

        offset += rawItems.length;
        if (offset >= total) break;
      }

      if (!mounted) return;

      setState(() {
        _issues = loaded;
        _clearFilterSelections();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<String> _options(String field) {
    final values =
        _issues
            .map((issue) => issue[field] ?? '')
            .where((value) => value.isNotEmpty && value != 'All')
            .toSet()
            .toList()
          ..sort();

    return ['All', ...values];
  }

  List<Map<String, String>> get _filteredIssues {
    final search = _query.trim().toLowerCase();

    return _issues.where((issue) {
      final matchesSearch = issue.values.any(
        (value) => value.toLowerCase().contains(search),
      );

      final range = _appliedDates;
      final date = DateTime.tryParse(issue['date'] ?? '');

      final matchesDate =
          range == null ||
          (date != null &&
              !date.isBefore(DateUtils.dateOnly(range.start)) &&
              !date.isAfter(DateUtils.dateOnly(range.end)));

      return matchesSearch &&
          (_appliedStatus == 'All' || issue['status'] == _appliedStatus) &&
          (_appliedPriority == 'All' ||
              issue['priority'] == _appliedPriority) &&
          (_appliedLocation == 'All' ||
              issue['location'] == _appliedLocation) &&
          matchesDate;
    }).toList();
  }

  int get _activeFilterCount => [
    _appliedStatus != 'All',
    _appliedPriority != 'All',
    _appliedLocation != 'All',
    _appliedDates != null,
  ].where((active) => active).length;

  void _clearFilterSelections() {
    _appliedStatus = 'All';
    _appliedPriority = 'All';
    _appliedLocation = 'All';
    _appliedDates = null;
  }

  void _clearAll() {
    _searchController.clear();

    setState(() {
      _query = '';
      _clearFilterSelections();
    });
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openWasteFilterSheet() async {
    String tempStatus = _appliedStatus;
    String tempPriority = _appliedPriority;
    String tempLocation = _appliedLocation;
    DateTimeRange? tempDates = _appliedDates;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Filter Waste Problems',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('filter-status-$tempStatus'),
                        initialValue: tempStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _options('status')
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => tempStatus = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('filter-priority-$tempPriority'),
                        initialValue: tempPriority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: _options('priority')
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => tempPriority = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('filter-location-$tempLocation'),
                        initialValue: tempLocation,
                        decoration: const InputDecoration(labelText: 'Location'),
                        items: _options('location')
                            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => tempLocation = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100, 12, 31),
                            initialDateRange: tempDates,
                          );
                          if (picked != null) {
                            setModalState(() => tempDates = picked);
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          tempDates == null
                              ? 'Select date range'
                              : '${_formatDate(tempDates!.start)} – ${_formatDate(tempDates!.end)}',
                        ),
                      ),
                      if (tempDates != null)
                        TextButton(
                          onPressed: () => setModalState(() => tempDates = null),
                          child: const Text('Clear date range'),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _appliedStatus = tempStatus;
                                  _appliedPriority = tempPriority;
                                  _appliedLocation = tempLocation;
                                  _appliedDates = tempDates;
                                });
                                Navigator.pop(context, true);
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              _clearAll();
                              Navigator.pop(context, true);
                            },
                            child: const Text('Reset All'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIssues;
    final totalCount = _issues.length;
    final resolvedCount = _issues.where((issue) {
      return ['resolved', 'closed'].contains(issue['status']!.toLowerCase());
    }).length;
    final activeCount = totalCount - resolvedCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Waste Problems'),
        actions: [
          IconButton(
            tooltip: 'Track Waste Locations on Map',
            onPressed: () => _openScreen(
              const DomainLocationTrackerScreen(category: 'waste'),
            ),
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            tooltip: 'Submit Waste Report',
            onPressed: () => QuickIssueReportSheet.show(
              context,
              initialCategory: 'waste',
              onSubmitted: _loadIssues,
            ),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadIssues,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => QuickIssueReportSheet.show(
          context,
          initialCategory: 'waste',
          onSubmitted: _loadIssues,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Waste Report',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  color: AppColors.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'City Waste Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Monitor waste collection, garbage overflow, and disposal reports.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        total: totalCount,
                        active: activeCount,
                        resolved: resolvedCount,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _query = val),
                        decoration: InputDecoration(
                          hintText: 'Search waste reports...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => QuickIssueReportSheet.show(
                              context,
                              initialCategory: 'waste',
                              onSubmitted: _loadIssues,
                            ),
                            icon: const Icon(Icons.add_task_rounded, size: 18),
                            label: const Text('Report Waste Issue'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openWasteFilterSheet,
                            icon: const Icon(Icons.tune),
                            label: Text(
                              _activeFilterCount > 0
                                  ? 'Filters ($_activeFilterCount)'
                                  : 'Filters',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openScreen(
                              const DomainLocationTrackerScreen(category: 'waste'),
                            ),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Live Map'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openScreen(
                              const CollectionInformationScreen(),
                            ),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: const Text('Schedules'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openScreen(
                              const RecyclingInformationScreen(),
                            ),
                            icon: const Icon(Icons.recycling_rounded),
                            label: const Text('Recycling'),
                          ),
                          if (_activeFilterCount > 0)
                            IconButton(
                              tooltip: 'Clear filters',
                              onPressed: _clearAll,
                              icon: const Icon(Icons.filter_alt_off_outlined),
                            ),
                          if (!_loading)
                            Text(
                              '${filtered.length} reports',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null && _issues.isEmpty
                          ? _statusView(
                              icon: Icons.wifi_off_outlined,
                              title: 'Unable to load waste reports',
                              message: _error!,
                              onRetry: _loadIssues,
                            )
                          : filtered.isEmpty
                              ? _statusView(
                                  icon: _issues.isEmpty
                                      ? Icons.delete_outline_rounded
                                      : Icons.search_off,
                                  title: _issues.isEmpty
                                      ? 'No waste reports yet'
                                      : 'No matching waste reports',
                                  message: _issues.isEmpty
                                      ? 'Report missed pickups, overflowing bins, or illegal dumping in your area.'
                                      : 'Try adjusting your search terms or filters.',
                                  buttonLabel: _issues.isEmpty
                                      ? 'Submit Waste Report'
                                      : 'Clear filters',
                                  onRetry: _issues.isEmpty
                                      ? () => QuickIssueReportSheet.show(
                                            context,
                                            initialCategory: 'waste',
                                            onSubmitted: _loadIssues,
                                          )
                                      : _clearAll,
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadIssues,
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      return _issueRow(filtered[index]);
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required int total,
    required int active,
    required int resolved,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final cardWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Row(
          children: [
            _statItem('Total Reports', total, AppColors.cyan, Icons.assignment_outlined, cardWidth),
            const SizedBox(width: spacing),
            _statItem('Active / Open', active, AppColors.warning, Icons.pending_actions_rounded, cardWidth),
            const SizedBox(width: spacing),
            _statItem('Resolved', resolved, AppColors.success, Icons.check_circle_outline_rounded, cardWidth),
          ],
        );
      },
    );
  }

  Widget _statItem(String label, int count, Color color, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusView({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback onRetry,
    String buttonLabel = 'Try again',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Widget _badgeChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _issueRow(Map<String, String> issue) {
    final isStaff = context.watch<AuthProvider>().user?.isStaff ?? false;
    final idInt = int.tryParse(issue['id'] ?? '') ?? 0;
    final priority = issue['priority'] ?? 'Medium';
    final status = issue['status'] ?? 'Reported';
    final desc = (issue['description'] ?? '').trim();
    final loc = issue['location'] ?? 'Location not provided';
    final date = issue['date'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => WasteProblemDetailsScreen(issue: issue),
            ),
          );
          if (mounted) _loadIssues();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      issue['title'] ?? 'Waste issue',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _badgeChip(priority, _priorityColor(priority)),
                  _badgeChip(status, AppColors.primary),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 17,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      loc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Report #${issue['id'] ?? ''} • Reported $date',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isStaff && idInt > 0)
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.lightBlue,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TrafficStatusManagementScreen(
                              issueId: idInt,
                              categoryLabel: 'Waste',
                            ),
                          ),
                        );
                        if (mounted) _loadIssues();
                      },
                      icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                      label: const Text(
                        'Manage Case',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
