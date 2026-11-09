
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:smart_city_app/features/auth/providers/auth_provider.dart';
import 'package:smart_city_app/features/reporting/widgets/issue_location_tracker_card.dart';
import 'package:smart_city_app/features/reporting/widgets/quick_issue_report_sheet.dart';

import '../providers/energy_water_provider.dart';
import '../widgets/water_issue_card.dart';
import 'water_issue_details_screen.dart';
import 'water_leakage_reports_screen.dart';

class WaterProblemsScreen extends StatefulWidget {
  const WaterProblemsScreen({super.key});

  @override
  State<WaterProblemsScreen> createState() => _WaterProblemsScreenState();
}

class _WaterProblemsScreenState extends State<WaterProblemsScreen> {
  final EnergyWaterProvider _provider = EnergyWaterProvider();
  final TextEditingController _searchController = TextEditingController();

  static const _statuses = ['reported', 'in_progress', 'resolved'];
  static const _priorities = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      _provider.reportedBy = (user != null && user.isCitizen) ? user.id : null;
      _provider.loadWaterIssues();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _openReportSheet() {
    QuickIssueReportSheet.show(
      context,
      initialCategory: 'water',
      initialSubcategory: 'supply',
      onSubmitted: _provider.loadWaterIssues,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _provider.setWaterSearch('');
  }

  void _clearAllFilters() {
    _searchController.clear();
    _provider.setWaterStatus(null);
    _provider.setWaterPriority(null);
    _provider.setWaterSearch('');
  }

  Future<void> _openFilterSheet() async {
    String? tempStatus = _provider.waterStatus;
    String? tempPriority = _provider.waterPriority;

    final changed = await showModalBottomSheet<bool>(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter Water Problems',
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
                      key: ValueKey('status-$tempStatus'),
                      initialValue: tempStatus ?? '',
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('All statuses')),
                        ..._statuses.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.replaceAll('_', ' ').toUpperCase()),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setModalState(() => tempStatus = val?.isEmpty == true ? null : val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('priority-$tempPriority'),
                      initialValue: tempPriority ?? '',
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('All priorities')),
                        ..._priorities.map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.toUpperCase()),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setModalState(() => tempPriority = val?.isEmpty == true ? null : val);
                      },
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
                              _provider.setWaterStatus(tempStatus);
                              _provider.setWaterPriority(tempPriority);
                              Navigator.pop(context, true);
                            },
                            child: const Text('Apply Filters'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            _clearAllFilters();
                            Navigator.pop(context, true);
                          },
                          child: const Text('Reset All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (changed == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Water Problems'),
        actions: [
          IconButton(
            tooltip: 'Track Water Locations on Map',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const DomainLocationTrackerScreen(category: 'water'),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            tooltip: 'Submit Water Report',
            onPressed: _openReportSheet,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _provider.loadWaterIssues,
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
          'New Water Report',
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
                        'City Water Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage water supply shortages, pipe bursts, and water contamination reports.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ListenableBuilder(
                        listenable: _provider,
                        builder: (context, _) {
                          final issues = _provider.waterIssues;
                          final total = issues.length;
                          final resolved = issues
                              .where((i) => ['resolved', 'closed'].contains(i.status.toLowerCase()))
                              .length;
                          final active = total - resolved;

                          return _buildStatRow(
                            total: total,
                            active: active,
                            resolved: resolved,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: _provider.setWaterSearch,
                        decoration: InputDecoration(
                          hintText: 'Search water reports...',
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
                      ListenableBuilder(
                        listenable: _provider,
                        builder: (context, _) {
                          final hasFilters = _provider.waterStatus != null ||
                              _provider.waterPriority != null;

                          return Wrap(
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
                                label: const Text('Report Water Issue'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _openFilterSheet,
                                icon: const Icon(Icons.tune),
                                label: Text(
                                  hasFilters ? 'Filters applied' : 'Filters',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const DomainLocationTrackerScreen(
                                        category: 'water',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Live Map'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const WaterLeakageReportsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.location_on_rounded),
                                label: const Text('Leakage Map'),
                              ),
                              if (hasFilters)
                                IconButton(
                                  tooltip: 'Clear filters',
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(Icons.filter_alt_off_outlined),
                                ),
                              if (!_provider.waterLoading)
                                Text(
                                  '${_provider.waterIssues.length} reports',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _provider,
                    builder: (context, _) {
                      if (_provider.waterLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_provider.waterError != null && _provider.waterIssues.isEmpty) {
                        return _statusView(
                          icon: Icons.wifi_off_outlined,
                          title: 'Unable to load water reports',
                          message: _provider.waterError!,
                          onRetry: _provider.loadWaterIssues,
                        );
                      }
                      if (_provider.waterIssues.isEmpty) {
                        final hasFilters = _provider.waterStatus != null ||
                            _provider.waterPriority != null;
                        return _statusView(
                          icon: hasFilters ? Icons.search_off : Icons.water_drop_outlined,
                          title: hasFilters
                              ? 'No matching water reports'
                              : 'No water reports yet',
                          message: hasFilters
                              ? 'Try adjusting your search terms or filters.'
                              : 'Report low pressure, supply cuts, pipeline leaks, or quality issues.',
                          buttonLabel: hasFilters ? 'Clear filters' : 'Submit Water Report',
                          onRetry: hasFilters ? _clearAllFilters : _openReportSheet,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _provider.loadWaterIssues,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                          itemCount: _provider.waterIssues.length,
                          itemBuilder: (context, index) {
                            final issue = _provider.waterIssues[index];
                            return WaterIssueCard(
                              issue: issue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WaterIssueDetailsScreen(
                                      issue: issue,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
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
}
