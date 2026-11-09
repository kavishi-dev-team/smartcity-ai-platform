import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../traffic/screens/traffic_problem_details_screen.dart';
import '../../traffic/screens/traffic_status_management_screen.dart';
import '../../waste/screens/waste_problem_details_screen.dart';
import '../widgets/issue_location_tracker_card.dart';
import '../widgets/quick_issue_report_sheet.dart';
import 'report_details_screen.dart';

class MyReportsScreen extends StatefulWidget {
  final bool embedded;
  final bool showAllCityReports;
  final String initialStatus;
  final String initialCategory;
  final int refreshToken;
  final VoidCallback? onBackToDashboard;

  const MyReportsScreen({
    super.key,
    this.embedded = false,
    this.showAllCityReports = false,
    this.initialStatus = 'all',
    this.initialCategory = 'all',
    this.refreshToken = 0,
    this.onBackToDashboard,
  });

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  late String _selectedCategory;
  late String _selectedStatus;
  late bool _onlyMine;

  int? _lastLoadedUserId;
  int _lastDashboardRefreshVersion = -1;

  static const _categories = [
    ('all', 'All Categories'),
    ('waste', 'Waste'),
    ('energy', 'Energy'),
    ('water', 'Water'),
    ('traffic', 'Traffic'),
    ('safety', 'Safety'),
    ('complaint', 'Complaint'),
  ];

  static const _statuses = [
    ('all', 'All Reports'),
    ('active', 'Active Reports'),
    ('reported', 'Reported'),
    ('in_progress', 'In Progress'),
    ('resolved', 'Resolved'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _statusShortLabel(String status) {
    switch (status) {
      case 'all':
        return 'Status: All';
      case 'active':
        return 'Active';
      case 'reported':
        return 'Reported';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String _categoryLabel(String category) {
    for (final (v, l) in _categories) {
      if (v == category) return l;
    }
    return category.toUpperCase();
  }

  void _showStatusPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter by Status',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedStatus != 'all')
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _selectedStatus = 'all');
                          _loadReports();
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final (value, label) in _statuses)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    selected: _selectedStatus == value,
                    selectedTileColor: AppColors.lightBlue,
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: value == 'all'
                            ? AppColors.primary
                            : value == 'active'
                                ? AppColors.warning
                                : _statusColor(value),
                      ),
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        fontWeight: _selectedStatus == value
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _selectedStatus == value
                            ? AppColors.primaryDark
                            : AppColors.text,
                        fontSize: 14,
                      ),
                    ),
                    trailing: _selectedStatus == value
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedStatus = value);
                      _loadReports();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernCategoryCarousel() {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, 0.88, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final (value, label) = _categories[index];
            final isSelected = _selectedCategory == value;
            return InkWell(
              onTap: () {
                setState(() => _selectedCategory = value);
                _loadReports();
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.lightBlue.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(value),
                      size: 15,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    final hasCategoryFilter = _selectedCategory != 'all';
    final hasStatusFilter = _selectedStatus != 'all';
    final hasSearch = _search.trim().isNotEmpty;

    if (!hasCategoryFilter && !hasStatusFilter && !hasSearch) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              [
                if (hasCategoryFilter) _categoryLabel(_selectedCategory),
                if (hasStatusFilter) _statusShortLabel(_selectedStatus),
                if (hasSearch) '"${_search.trim()}"',
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              _searchController.clear();
              setState(() {
                _selectedCategory = 'all';
                _selectedStatus = 'all';
                _search = '';
              });
              _loadReports();
            },
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close_rounded,
                      size: 13, color: AppColors.primary),
                  SizedBox(width: 2),
                  Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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

  @override
  void initState() {
    super.initState();
    _onlyMine = !widget.showAllCityReports;
    _selectedCategory = widget.initialCategory;
    _selectedStatus = widget.initialStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadReports();
    });
  }

  @override
  void didUpdateWidget(covariant MyReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool shouldReload = false;
    if (oldWidget.initialStatus != widget.initialStatus) {
      _selectedStatus = widget.initialStatus;
      shouldReload = true;
    }
    if (oldWidget.initialCategory != widget.initialCategory) {
      _selectedCategory = widget.initialCategory;
      shouldReload = true;
    }
    if (oldWidget.refreshToken != widget.refreshToken) {
      shouldReload = true;
    }
    if (shouldReload) {
      _loadReports();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authUser = context.watch<AuthProvider>().user;
    final dashProvider = context.watch<DashboardProvider>();
    final effectiveUserId = authUser?.id ?? dashProvider.currentUserId;

    final userChanged = effectiveUserId != _lastLoadedUserId;
    final dashRefreshed =
        dashProvider.refreshVersion != _lastDashboardRefreshVersion;

    if (userChanged || dashRefreshed) {
      _lastLoadedUserId = effectiveUserId;
      _lastDashboardRefreshVersion = dashProvider.refreshVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadReports();
      });
    }
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final dash = context.read<DashboardProvider>();
      final userId = auth.user?.id ?? dash.currentUserId;

      // If viewing "My Reports" and user session hasn't resolved an ID yet,
      // avoid fetching global reports belonging to other users.
      if (_onlyMine && userId == null) {
        if (!mounted) return;
        setState(() {
          _reports = [];
          _loading = false;
        });
        return;
      }

      final queryParams = <String, String>{
        'category': _selectedCategory,
        'limit': '100',
      };
      if (_onlyMine && userId != null) {
        queryParams['reported_by'] = userId.toString();
      }
      if (_selectedStatus != 'all') {
        queryParams['status'] = _selectedStatus;
      }
      if (_search.trim().isNotEmpty) {
        queryParams['search'] = _search.trim();
      }

      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/issues',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(AppConfig.requestTimeout);
      if (response.statusCode != 200) {
        throw Exception('Failed to load reports (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawItems = (data['items'] as List<dynamic>? ?? []);
      var parsedItems = rawItems
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Ensure client-side status filter consistency for 'active'
      if (_selectedStatus == 'active') {
        parsedItems = parsedItems.where((item) {
          final s = (item['status'] ?? 'reported').toString().toLowerCase();
          return s != 'resolved';
        }).toList();
      }

      // Fallback to CitizenDashboard recentReports if the list endpoint returned
      // empty while CitizenDashboard already has loaded reports for this user
      if (parsedItems.isEmpty &&
          _onlyMine &&
          _selectedCategory == 'all' &&
          _search.trim().isEmpty &&
          dash.citizenDashboard != null &&
          dash.citizenDashboard!.recentReports.isNotEmpty) {
        final fallback = dash.citizenDashboard!.recentReports
            .where((r) {
              final s = r.status.toLowerCase();
              if (_selectedStatus == 'all') return true;
              if (_selectedStatus == 'active') return s != 'resolved';
              return s == _selectedStatus.toLowerCase();
            })
            .map(
              (r) => <String, dynamic>{
                'id': r.id,
                'title': r.title,
                'description': r.description,
                'category': r.category,
                'status': r.status,
                'priority': r.priority,
                'created_at': r.createdAt.toIso8601String(),
                'locations': const <Map<String, dynamic>>[],
              },
            )
            .toList();
        parsedItems = fallback;
      }

      if (!mounted) return;
      setState(() {
        _reports = parsedItems;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'waste':
        return Icons.delete_outline_rounded;
      case 'energy':
        return Icons.bolt_rounded;
      case 'water':
        return Icons.water_drop_outlined;
      case 'traffic':
        return Icons.traffic_rounded;
      case 'safety':
        return Icons.shield_outlined;
      case 'complaint':
        return Icons.record_voice_over_outlined;
      default:
        return Icons.report_problem_outlined;
    }
  }

  void _openReport(Map<String, dynamic> item) {
    final id = item['id'] is int
        ? item['id'] as int
        : int.tryParse(item['id'].toString()) ?? 0;
    final category = (item['category'] ?? '').toString().toLowerCase();

    if (category == 'traffic' && id > 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TrafficProblemDetailsScreen(issueId: id),
        ),
      );
      return;
    }

    if (category == 'waste' && id > 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WasteProblemDetailsScreen(
            issue: {
              'id': id.toString(),
              'title': (item['title'] ?? 'Waste Issue').toString(),
              'description': (item['description'] ?? '').toString(),
              'status': (item['status'] ?? 'Reported').toString(),
              'priority': (item['priority'] ?? 'Medium').toString(),
            },
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportDetailsScreen(issueId: id, initialData: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isCitizen = user?.isCitizen ?? true;
    final dashboard = context.watch<DashboardProvider>().citizenDashboard;

    final totalCount = dashboard?.totalReports ?? _reports.length;
    final activeCount = dashboard?.activeReports ??
        _reports
            .where(
              (r) =>
                  (r['status'] ?? 'reported').toString().toLowerCase() !=
                  'resolved',
            )
            .length;
    final resolvedCount = dashboard?.resolvedReports ??
        _reports
            .where(
              (r) =>
                  (r['status'] ?? '').toString().toLowerCase() == 'resolved',
            )
            .length;

    final body = Column(
      children: [
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Interactive Summary Filter Cards (Total / Active / Resolved)
              Row(
                children: [
                  Expanded(
                    child: _summaryFilterPill(
                      label: 'Total Reports',
                      count: totalCount,
                      color: AppColors.primary,
                      selected: _selectedStatus == 'all',
                      onTap: () {
                        setState(() => _selectedStatus = 'all');
                        _loadReports();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryFilterPill(
                      label: 'Active',
                      count: activeCount,
                      color: AppColors.warning,
                      selected: _selectedStatus == 'active',
                      onTap: () {
                        setState(() => _selectedStatus = 'active');
                        _loadReports();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryFilterPill(
                      label: 'Resolved',
                      count: resolvedCount,
                      color: AppColors.success,
                      selected: _selectedStatus == 'resolved',
                      onTap: () {
                        setState(() => _selectedStatus = 'resolved');
                        _loadReports();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search Bar + Status Filter Dropdown Pill + Map/Scope
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) {
                        _search = v;
                        _loadReports();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search your reports...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _search = '';
                                  _loadReports();
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Modern Status Dropdown Pill
                  InkWell(
                    onTap: _showStatusPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedStatus != 'all'
                            ? AppColors.lightBlue
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedStatus != 'all'
                              ? AppColors.primary
                              : AppColors.border,
                          width: _selectedStatus != 'all' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _selectedStatus == 'all'
                                  ? AppColors.primary
                                  : _selectedStatus == 'active'
                                      ? AppColors.warning
                                      : _statusColor(_selectedStatus),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusShortLabel(_selectedStatus),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedStatus != 'all'
                                  ? AppColors.primaryDark
                                  : AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 18,
                            color: _selectedStatus != 'all'
                                ? AppColors.primaryDark
                                : AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isCitizen)
                    InkWell(
                      onTap: () {
                        setState(() => _onlyMine = !_onlyMine);
                        _loadReports();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _onlyMine
                              ? AppColors.lightBlue
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _onlyMine
                                ? AppColors.primary
                                : AppColors.border,
                            width: _onlyMine ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _onlyMine
                                  ? Icons.person_rounded
                                  : Icons.public_rounded,
                              size: 15,
                              color: _onlyMine
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _onlyMine ? 'Mine' : 'All',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _onlyMine
                                    ? AppColors.primaryDark
                                    : AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.lightBlue,
                        foregroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(9),
                      ),
                      tooltip: 'Live Problem Location Map',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DomainLocationTrackerScreen(
                              category: _selectedCategory,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined, size: 20),
                    ),
                ],
              ),
              _buildActiveFiltersBar(),
              const SizedBox(height: 10),
            ],
          ),
        ),
        // Modern Category Selection Carousel (Single row, edge-faded, non-cracking)
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildModernCategoryCarousel(),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.error,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: _loadReports,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _reports.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.assignment_outlined,
                                  size: 54,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedStatus == 'resolved'
                                      ? 'No resolved reports yet'
                                      : _selectedStatus == 'active'
                                          ? 'No active reports found'
                                          : 'No matching reports found',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedStatus != 'all' ||
                                          _selectedCategory != 'all'
                                      ? 'Try switching filters to "All Reports" / "All Categories" or submit a new city report.'
                                      : 'Submit a new city report to track its live status and location.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    if (_selectedStatus != 'all' ||
                                        _selectedCategory != 'all')
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _selectedStatus = 'all';
                                            _selectedCategory = 'all';
                                          });
                                          _loadReports();
                                        },
                                        icon: const Icon(
                                          Icons.filter_alt_off_outlined,
                                        ),
                                        label: const Text('Show All My Reports'),
                                      ),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await QuickIssueReportSheet.show(
                                          context,
                                          initialCategory:
                                              _selectedCategory == 'all'
                                                  ? 'waste'
                                                  : _selectedCategory,
                                          onSubmitted: _loadReports,
                                        );
                                      },
                                      icon: const Icon(Icons.add_location_alt),
                                      label: const Text('Submit New Report'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReports,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: _reports.length,
                            itemBuilder: (context, index) {
                              final item = _reports[index];
                              final cat = (item['category'] ?? 'general')
                                  .toString();
                              final status = (item['status'] ?? 'reported')
                                  .toString();
                              final priority = (item['priority'] ?? 'medium')
                                  .toString();
                              final desc = (item['description'] ?? '')
                                  .toString();
                              final locs =
                                  item['locations'] as List<dynamic>? ?? [];
                              final singleLoc =
                                  item['location'] as Map<String, dynamic>?;
                              String city = '';
                              String address = '';
                              if (locs.isNotEmpty && locs.first is Map) {
                                city = (locs.first['city'] ?? '').toString();
                                address =
                                    (locs.first['address'] ?? '').toString();
                              } else if (singleLoc != null) {
                                city = (singleLoc['city'] ?? '').toString();
                                address =
                                    (singleLoc['address'] ?? '').toString();
                              }
                              final locationLabel = address.isNotEmpty &&
                                      city.isNotEmpty &&
                                      !address
                                          .toLowerCase()
                                          .contains(city.toLowerCase())
                                  ? '$address, $city'
                                  : (address.isNotEmpty ? address : city);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _openReport(item),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.categoryColor(cat)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            AppColors.categoryIcon(cat),
                                            color: AppColors.categoryColor(cat),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (item['title'] ??
                                                        'Untitled Issue')
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.5,
                                                  color: AppColors.text,
                                                ),
                                              ),
                                              if (desc.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  desc,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: AppColors.muted,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  Text(
                                                    cat.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .categoryColor(cat),
                                                    ),
                                                  ),
                                                  const Text(
                                                    '•',
                                                    style: TextStyle(
                                                      color: AppColors.muted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 7,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _statusColor(
                                                        status,
                                                      ).withValues(alpha: 0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      status
                                                          .replaceAll('_', ' ')
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _statusColor(
                                                          status,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Text(
                                                    '•',
                                                    style: TextStyle(
                                                      color: AppColors.muted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Priority: ${priority.toUpperCase()}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.muted,
                                                    ),
                                                  ),
                                                  if (locationLabel
                                                      .isNotEmpty) ...[
                                                    const Text(
                                                      '•',
                                                      style: TextStyle(
                                                        color: AppColors.muted,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .location_on_outlined,
                                                          size: 12,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                        const SizedBox(
                                                          width: 2,
                                                        ),
                                                        Flexible(
                                                          child: Text(
                                                            locationLabel,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppColors
                                                                  .primaryDark,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!isCitizen)
                                          FilledButton.tonalIcon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.lightBlue,
                                              foregroundColor:
                                                  AppColors.primaryDark,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              minimumSize: const Size(0, 32),
                                              tapTargetSize: MaterialTapTargetSize
                                                  .shrinkWrap,
                                            ),
                                            onPressed: () async {
                                              final id = item['id'] is int
                                                  ? item['id'] as int
                                                  : int.tryParse(
                                                          item['id'].toString(),
                                                        ) ??
                                                        0;
                                              if (id > 0) {
                                                await Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        TrafficStatusManagementScreen(
                                                          issueId: id,
                                                          categoryLabel: cat
                                                              .toUpperCase(),
                                                        ),
                                                  ),
                                                );
                                                if (mounted) _loadReports();
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.manage_accounts_rounded,
                                              size: 15,
                                            ),
                                            label: const Text(
                                              'Manage',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        else
                                          const Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded && widget.onBackToDashboard != null
            ? IconButton(
                onPressed: widget.onBackToDashboard,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Dashboard',
              )
            : null,
        title: Text(_onlyMine ? 'My City Reports' : 'All City Reports'),
        actions: [
          IconButton(
            onPressed: () {
              QuickIssueReportSheet.show(
                context,
                initialCategory:
                    _selectedCategory == 'all' ? 'waste' : _selectedCategory,
                onSubmitted: _loadReports,
              );
            },
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Submit New Report',
          ),
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _summaryFilterPill({
    required String label,
    required int count,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.14)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: selected ? color : AppColors.text,
                  ),
                ),
                const Spacer(),
                if (selected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? color : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
