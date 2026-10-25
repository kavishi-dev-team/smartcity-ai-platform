import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:smart_city_app/features/notifications/screens/notifications_screen.dart';

import '../services/waste_service.dart';
import 'collection_information_screen.dart';
import 'recycling_information_screen.dart';
import 'waste_problem_details_screen.dart';
import 'waste_separation_guide_screen.dart';

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
  bool _showFilters = false;

  String _status = 'All';
  String _priority = 'All';
  String _location = 'All';
  DateTimeRange? _dates;

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
      // Fetch every page so local search and filters cover all reports.
      final loaded = <Map<String, String>>[];
      var offset = 0;

      while (true) {
        final response = await _service.getWasteIssues(
          offset: offset,
          limit: 100,
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
    _status = 'All';
    _priority = 'All';
    _location = 'All';
    _dates = null;
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

  void _applyFilters() {
    setState(() {
      _appliedStatus = _status;
      _appliedPriority = _priority;
      _appliedLocation = _location;
      _appliedDates = _dates;
    });
  }

  Future<void> _pickDates() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: _dates,
    );

    if (!mounted || result == null) return;
    setState(() => _dates = result);
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIssues;
    final resolved = _issues.where((issue) {
      return ['resolved', 'closed'].contains(issue['status']!.toLowerCase());
    }).length;
    final statsAvailable = !_loading && _error == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Waste'),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: _loading ? null : _loadIssues,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _openScreen(const NotificationsScreen()),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENVIRONMENTAL SERVICES',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Waste management',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openScreen(const CollectionInformationScreen()),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Collection schedules'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openScreen(const WasteSeparationGuideScreen()),
                      icon: const Icon(Icons.recycling),
                      label: const Text('Waste separation guide'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openScreen(const RecyclingInformationScreen()),
                      icon: const Icon(Icons.eco_outlined),
                      label: const Text('Recycling information'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manage collection schedules, missed pickups, and recycling.',
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600 ? 3 : 2;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 12) / columns;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _statCard(
                          width,
                          'Total reports',
                          statsAvailable ? '${_issues.length}' : '—',
                          Icons.assignment_outlined,
                        ),
                        _statCard(
                          width,
                          'Open reports',
                          statsAvailable ? '${_issues.length - resolved}' : '—',
                          Icons.pending_actions,
                        ),
                        _statCard(
                          width,
                          'Resolved / closed',
                          statsAvailable ? '$resolved' : '—',
                          Icons.task_alt,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waste management overview',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadIssues,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ] else ...[
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Search issues...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _showFilters = !_showFilters),
                          icon: const Icon(Icons.filter_list),
                          label: Text('Filters ($_activeFilterCount)'),
                        ),
                        if (_showFilters) ...[
                          const SizedBox(height: 16),
                          _dropdown(
                            'Status',
                            _status,
                            _options('status'),
                            (value) => setState(() => _status = value),
                          ),

                          _dropdown(
                            'Priority',
                            _priority,
                            _options('priority'),
                            (value) => setState(() => _priority = value),
                          ),
                          _dropdown(
                            'Location',
                            _location,
                            _options('location'),
                            (value) => setState(() => _location = value),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickDates,
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              _dates == null
                                  ? 'Select date range'
                                  : '${_formatDate(_dates!.start)} – '
                                        '${_formatDate(_dates!.end)}',
                            ),
                          ),
                          if (_dates != null)
                            TextButton(
                              onPressed: () => setState(() => _dates = null),
                              child: const Text('Remove date selection'),
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            children: [
                              FilledButton(
                                onPressed: _applyFilters,
                                child: const Text('Apply filters'),
                              ),
                              TextButton(
                                onPressed: _clearAll,
                                child: const Text('Clear all'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          '${filtered.length} results '
                          'from ${_issues.length} reports',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    size: 36,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _issues.isEmpty
                                        ? 'No waste reports yet.'
                                        : 'No matching waste issues.',
                                  ),
                                  if (_issues.isNotEmpty)
                                    TextButton(
                                      onPressed: _clearAll,
                                      child: const Text('Reset all'),
                                    ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...filtered.map(_issueRow),
                      ],
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

  Widget _dropdown(
    String label,
    String selected,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$selected'),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: options.map((option) {
          return DropdownMenuItem<String>(value: option, child: Text(option));
        }).toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  Widget _statCard(double width, String label, String value, IconData icon) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _issueRow(Map<String, String> issue) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(
        '#${issue['id']} • ${issue['title']}',
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${issue['location']} • ${issue['date']}\n'
        '${issue['status']} • ${issue['priority']} priority',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openScreen(WasteProblemDetailsScreen(issue: issue)),
    );
  }
}
