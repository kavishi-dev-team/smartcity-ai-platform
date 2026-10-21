import 'package:smart_city_app/features/notifications/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';
import 'collection_information_screen.dart';
import 'waste_problem_details_screen.dart';
import 'waste_separation_guide_screen.dart';
import 'recycling_information_screen.dart';

class WasteProblemsScreen extends StatefulWidget {
  const WasteProblemsScreen({super.key});

  @override
  State<WasteProblemsScreen> createState() => _WasteProblemsScreenState();
}

class _WasteProblemsScreenState extends State<WasteProblemsScreen> {
  static const _blue = AppColors.primary;
  static const _navy = AppColors.text;
  static const _muted = AppColors.muted;
  static const _border = AppColors.border;

  final _searchController = TextEditingController();

  String _query = '';

  // Selections currently shown in the filter controls.
  String _status = 'All';
  String _type = 'All';
  String _priority = 'All';
  String _location = 'All';
  DateTimeRange? _dates;

  // Selections applied to the issue list.
  String _appliedStatus = 'All';
  String _appliedType = 'All';
  String _appliedPriority = 'All';
  String _appliedLocation = 'All';
  DateTimeRange? _appliedDates;

  bool _showFilters = false;

  static const List<Map<String, String>> _issues = [
    {
      'id': 'WR-2052',
      'title': 'Missed recycling',
      'location': 'Colombo 07',
      'status': 'Pending',
      'type': 'Recyclable',
      'priority': 'Medium',
      'date': '2026-10-19',
    },
    {
      'id': 'WR-2048',
      'title': 'Bulky waste pickup',
      'location': 'Nugegoda',
      'status': 'In progress',
      'type': 'Bulky',
      'priority': 'High',
      'date': '2026-10-18',
    },
    {
      'id': 'WR-2041',
      'title': 'Bin replacement',
      'location': 'Homagama',
      'status': 'Pending',
      'type': 'General',
      'priority': 'Low',
      'date': '2026-10-17',
    },
    {
      'id': 'WR-2037',
      'title': 'Missed collection',
      'location': 'Maharagama',
      'status': 'Resolved',
      'type': 'General',
      'priority': 'Medium',
      'date': '2026-10-16',
    },
  ];

  List<Map<String, String>> get _filteredIssues {
    final search = _query.trim().toLowerCase();

    return _issues.where((issue) {
      final matchesSearch = issue.values.any(
        (value) => value.toLowerCase().contains(search),
      );

      final matchesStatus =
          _appliedStatus == 'All' || issue['status'] == _appliedStatus;

      final matchesType =
          _appliedType == 'All' || issue['type'] == _appliedType;

      final matchesPriority =
          _appliedPriority == 'All' || issue['priority'] == _appliedPriority;

      final matchesLocation =
          _appliedLocation == 'All' || issue['location'] == _appliedLocation;

      final issueDate = DateTime.parse(issue['date']!);
      final range = _appliedDates;

      final matchesDate =
          range == null ||
          (!issueDate.isBefore(range.start) && !issueDate.isAfter(range.end));

      return matchesSearch &&
          matchesStatus &&
          matchesType &&
          matchesPriority &&
          matchesLocation &&
          matchesDate;
    }).toList();
  }

  int get _activeFilterCount {
    return [
      _appliedStatus != 'All',
      _appliedType != 'All',
      _appliedPriority != 'All',
      _appliedLocation != 'All',
      _appliedDates != null,
    ].where((active) => active).length;
  }

  void _applyFilters() {
    setState(() {
      _appliedStatus = _status;
      _appliedType = _type;
      _appliedPriority = _priority;
      _appliedLocation = _location;
      _appliedDates = _dates;
    });
  }

  void _clearAll() {
    _searchController.clear();

    setState(() {
      _query = '';

      _status = 'All';
      _type = 'All';
      _priority = 'All';
      _location = 'All';
      _dates = null;

      _appliedStatus = 'All';
      _appliedType = 'All';
      _appliedPriority = 'All';
      _appliedLocation = 'All';
      _appliedDates = null;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _pickDates() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
      initialDateRange: _dates,
      helpText: 'Select issue date range',
    );

    if (!mounted || selected == null) return;

    setState(() {
      _dates = selected;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issues = _filteredIssues;
    final dates = _dates;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF5FF),
      appBar: AppBar(
        title: const Text('Waste'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        foregroundColor: _navy,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
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
                    color: _blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Waste management',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const CollectionInformationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Collection schedules'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const WasteSeparationGuideScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.recycling),
                  label: const Text('Waste separation guide'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            const RecyclingInformationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.eco_outlined),
                  label: const Text('Recycling information'),
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 8),
                const Text(
                  'Manage collection schedules, missed pickups, '
                  'and recycling.',
                  style: TextStyle(color: _muted, height: 1.5),
                ),
                const SizedBox(height: 12),
                const Chip(
                  label: Text('Preview • Sample data'),
                  avatar: Icon(Icons.info_outline, size: 16),
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
                          Icons.delete_outline,
                          'Collections complete',
                          '96.4%',
                          const Color(0xFFE2EDFF),
                        ),
                        _statCard(
                          width,
                          Icons.assignment_outlined,
                          'Open requests',
                          '38',
                          const Color(0xFFE4F5FF),
                        ),
                        _statCard(
                          width,
                          Icons.recycling,
                          'Recycling rate',
                          '72%',
                          const Color(0xFFDDFBFF),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Waste management overview',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Browse waste issues in your city.',
                              style: TextStyle(color: _muted, fontSize: 12),
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() => _query = value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search issues...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _query = '');
                                        },
                                      ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showFilters = !_showFilters;
                                });
                              },
                              icon: const Icon(Icons.filter_list),
                              label: Text('Filters ($_activeFilterCount)'),
                            ),
                            if (_showFilters) ...[
                              const SizedBox(height: 16),
                              _dropdown(
                                label: 'Status',
                                selected: _status,
                                options: const [
                                  'All',
                                  'Pending',
                                  'In progress',
                                  'Resolved',
                                ],
                                onChanged: (value) {
                                  setState(() => _status = value);
                                },
                              ),
                              _dropdown(
                                label: 'Waste type',
                                selected: _type,
                                options: const [
                                  'All',
                                  'Recyclable',
                                  'Bulky',
                                  'General',
                                ],
                                onChanged: (value) {
                                  setState(() => _type = value);
                                },
                              ),
                              _dropdown(
                                label: 'Priority',
                                selected: _priority,
                                options: const ['All', 'Low', 'Medium', 'High'],
                                onChanged: (value) {
                                  setState(() => _priority = value);
                                },
                              ),
                              _dropdown(
                                label: 'Location',
                                selected: _location,
                                options: const [
                                  'All',
                                  'Colombo 07',
                                  'Nugegoda',
                                  'Homagama',
                                  'Maharagama',
                                ],
                                onChanged: (value) {
                                  setState(() => _location = value);
                                },
                              ),
                              const Text(
                                'Issue date',
                                style: TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _pickDates,
                                icon: const Icon(Icons.date_range),
                                label: Text(
                                  dates == null
                                      ? 'Select date range'
                                      : '${_formatDate(dates.start)} – '
                                            '${_formatDate(dates.end)}',
                                ),
                              ),
                              if (dates != null)
                                TextButton(
                                  onPressed: () {
                                    setState(() => _dates = null);
                                  },
                                  child: const Text('Remove date selection'),
                                ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _blue,
                                    ),
                                    onPressed: _applyFilters,
                                    icon: const Icon(Icons.check),
                                    label: const Text('Apply filters'),
                                  ),
                                  TextButton(
                                    onPressed: _clearAll,
                                    child: const Text('Clear all'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Click Apply filters after changing selections.',
                                style: TextStyle(color: _muted, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        color: const Color(0xFFF0F7FF),
                        child: Text(
                          'WASTE ISSUES • ${issues.length} results',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (issues.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  color: _muted,
                                  size: 36,
                                ),
                                const SizedBox(height: 10),
                                const Text('No waste issues found.'),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try different search or filters.',
                                  style: TextStyle(color: _muted),
                                ),
                                TextButton(
                                  onPressed: _clearAll,
                                  child: const Text('Reset all'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...issues.map(_issueRow),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Showing ${issues.length} '
                          'of ${_issues.length} records',
                          style: const TextStyle(color: _muted, fontSize: 12),
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

  Widget _dropdown({
    required String label,
    required String selected,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        // Rebuild the field when Clear all resets its selection.
        key: ValueKey('$label-$selected'),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: options.map((option) {
          return DropdownMenuItem(value: option, child: Text(option));
        }).toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  Widget _statCard(
    double width,
    IconData icon,
    String label,
    String value,
    Color background,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _blue, size: 28),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _issueRow(Map<String, String> issue) {
    final status = issue['status']!;

    final statusColor = switch (status) {
      'Resolved' => const Color(0xFF15803D),
      'In progress' => _blue,
      _ => const Color(0xFFB45309),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => WasteProblemDetailsScreen(issue: issue),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEDF2FA))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue['id']!,
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      issue['title']!,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${issue['location']} • ${issue['date']}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${issue['type']} • '
                          '${issue['priority']} priority',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}
