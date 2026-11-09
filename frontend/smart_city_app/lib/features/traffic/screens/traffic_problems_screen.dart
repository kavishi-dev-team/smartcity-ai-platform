import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reporting/widgets/quick_issue_report_sheet.dart';
import '../providers/traffic_provider.dart';
import '../services/traffic_service.dart';
import '../widgets/traffic_filter_sheet.dart';
import '../widgets/traffic_issue_card.dart';
import 'traffic_problem_details_screen.dart';
import 'traffic_incident_map_screen.dart';
import 'department_information_screen.dart';

class TrafficProblemsScreen extends StatefulWidget {
  final TrafficService? service;

  const TrafficProblemsScreen({super.key, this.service});

  @override
  State<TrafficProblemsScreen> createState() => _TrafficProblemsScreenState();
}

class _TrafficProblemsScreenState extends State<TrafficProblemsScreen> {
  late final TrafficService _service;
  late final bool _ownsService;
  late final TrafficProvider _provider;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? TrafficService();
    _provider = TrafficProvider(_service);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      _provider.reportedBy = (user != null && user.isCitizen) ? user.id : null;
      _provider.refresh();
    });
  }

  void _openReportSheet() {
    QuickIssueReportSheet.show(
      context,
      initialCategory: 'traffic',
      onSubmitted: _provider.refresh,
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _provider.dispose();
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  void _onSearch(String term) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _provider.updateSearch(term);
    });
  }

  Future<void> _openFilters() async {
    final value = await showModalBottomSheet<TrafficFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TrafficFilterSheet(initial: _provider.filters),
    );
    if (value != null && mounted) _provider.applyFilters(value);
  }

  void _clearSearch() {
    _searchTimer?.cancel();
    _searchController.clear();
    _provider.updateSearch('');
  }

  void _clearAll() {
    _searchTimer?.cancel();
    _searchController.clear();
    _provider.clearFilters();
  }

  Future<void> _openIssue(int id) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => TrafficProblemDetailsScreen(issueId: id, service: _service),
    ));
    if (mounted) _provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _provider.issues
        .where((i) => !['resolved', 'closed'].contains(i.status.toLowerCase()))
        .length;
    final resolvedCount = _provider.issues
        .where((i) => ['resolved', 'closed'].contains(i.status.toLowerCase()))
        .length;
    final totalCount = _provider.total > 0 ? _provider.total : _provider.issues.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Problems'),
        actions: [
          IconButton(
            tooltip: 'Track Traffic Locations on Map',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TrafficIncidentMapScreen(
                  service: _service,
                  openedFromList: true,
                ),
              ),
            ),
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            tooltip: 'Submit Traffic Report',
            onPressed: _openReportSheet,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _provider.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openReportSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Traffic Report',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: AppColors.background,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text(
                    'City Traffic Reports',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Explore reported road and traffic problems across city zones.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, _) => _buildStatRow(
                      total: totalCount,
                      active: activeCount,
                      resolved: resolvedCount,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search traffic reports...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _provider,
                    builder: (context, _) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _openReportSheet,
                          icon: const Icon(Icons.add_task_rounded, size: 18),
                          label: const Text('Report Traffic Issue'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openFilters,
                          icon: const Icon(Icons.tune),
                          label: Text(
                            _provider.filters.isActive
                                ? 'Filters applied'
                                : 'Filters',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TrafficIncidentMapScreen(
                                service: _service,
                                openedFromList: true,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Live Map'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DepartmentInformationScreen(
                                service: _service,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.apartment_outlined),
                          label: const Text('Departments'),
                        ),
                        if (_provider.filters.isActive)
                          IconButton(
                            tooltip: 'Clear filters',
                            onPressed: _clearAll,
                            icon: const Icon(Icons.filter_alt_off_outlined),
                          ),
                        if (!_provider.loading)
                          Text(
                            '${_provider.total} reports',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
              Expanded(
                child: AnimatedBuilder(animation: _provider, builder: (context, _) {
                  if (_provider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_provider.error != null && _provider.issues.isEmpty) {
                    return _StatusView(
                      icon: Icons.wifi_off_outlined,
                      title: 'Unable to load traffic reports',
                      message: _provider.error!,
                      onRetry: _provider.refresh,
                    );
                  }
                  if (_provider.issues.isEmpty) {
                    final hasFilters = _provider.filters.isActive ||
                        _provider.filters.search.trim().isNotEmpty;
                    return _StatusView(
                      icon: hasFilters
                          ? Icons.search_off
                          : Icons.traffic_rounded,
                      title: hasFilters
                          ? 'No matching traffic reports'
                          : 'No traffic reports yet',
                      message: hasFilters
                          ? 'Try a different search term or clear filters.'
                          : 'Report potholes, broken traffic lights, roadblocks, or accidents in your area.',
                      onRetry: hasFilters ? _clearAll : _openReportSheet,
                      buttonLabel: hasFilters
                          ? 'Clear filters'
                          : 'Submit Traffic Report',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _provider.refresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
                      itemCount: _provider.issues.length + (_provider.hasMore || _provider.error != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _provider.issues.length) {
                          if (_provider.error != null) {
                            return Column(children: [
                              Text(_provider.error!, textAlign: TextAlign.center),
                              TextButton(onPressed: _provider.loadMore, child: const Text('Retry loading more')),
                            ]);
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: _provider.loadingMore
                                  ? const CircularProgressIndicator()
                                  : OutlinedButton(
                                      onPressed: _provider.loadMore,
                                      child: const Text('Load more reports'),
                                    ),
                            ),
                          );
                        }
                        final issue = _provider.issues[index];
                        return TrafficIssueCard(issue: issue, onTap: () => _openIssue(issue.id));
                      },
                    ),
                  );
                }),
              ),
            ]),
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
            _statItem('Total Reports', total, AppColors.primary, Icons.assignment_outlined, cardWidth),
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
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  final String buttonLabel;

  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    this.buttonLabel = 'Try again',
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 54, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: onRetry, child: Text(buttonLabel)),
          ]),
        ),
      );
}
