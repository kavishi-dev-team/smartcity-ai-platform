import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:smart_city_app/features/auth/providers/auth_provider.dart';
import 'package:smart_city_app/features/reporting/widgets/issue_location_tracker_card.dart';
import 'package:smart_city_app/features/reporting/widgets/quick_issue_report_sheet.dart';

import '../providers/energy_water_provider.dart';
import '../widgets/energy_issue_card.dart';
import 'energy_issue_details_screen.dart';
import 'energy_water_statistics_screen.dart';

class EnergyProblemsScreen extends StatefulWidget {
  const EnergyProblemsScreen({super.key});

  @override
  State<EnergyProblemsScreen> createState() => _EnergyProblemsScreenState();
}

class _EnergyProblemsScreenState extends State<EnergyProblemsScreen> {
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
      _provider.loadEnergyIssues();
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
      initialCategory: 'energy',
      onSubmitted: _provider.loadEnergyIssues,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _provider.setSearch('');
  }

  void _clearAllFilters() {
    _searchController.clear();
    _provider.setStatus(null);
    _provider.setPriority(null);
    _provider.setSearch('');
  }

  Future<void> _openFilterSheet() async {
    String? tempStatus = _provider.status;
    String? tempPriority = _provider.priority;

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
                            'Filter Energy Problems',
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
                              _provider.setStatus(tempStatus);
                              _provider.setPriority(tempPriority);
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
        title: const Text('Energy Problems'),
        actions: [
          IconButton(
            tooltip: 'Track Energy Locations on Map',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const DomainLocationTrackerScreen(category: 'energy'),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            tooltip: 'Submit Energy Report',
            onPressed: _openReportSheet,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _provider.loadEnergyIssues,
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
          'New Energy Report',
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
                        'City Energy Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Track power grid outages, street lighting faults, and electrical hazards.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ListenableBuilder(
                        listenable: _provider,
                        builder: (context, _) {
                          final issues = _provider.energyIssues;
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
                        onChanged: _provider.setSearch,
                        decoration: InputDecoration(
                          hintText: 'Search energy reports...',
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
                          final hasFilters = _provider.status != null || _provider.priority != null;

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
                                label: const Text('Report Energy Issue'),
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
                                        category: 'energy',
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
                                      builder: (_) => const EnergyWaterStatisticsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.bar_chart_rounded),
                                label: const Text('Utility Stats'),
                              ),
                              if (hasFilters)
                                IconButton(
                                  tooltip: 'Clear filters',
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(Icons.filter_alt_off_outlined),
                                ),
                              if (!_provider.isLoading)
                                Text(
                                  '${_provider.energyIssues.length} reports',
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
                      if (_provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_provider.error != null && _provider.energyIssues.isEmpty) {
                        return _statusView(
                          icon: Icons.wifi_off_outlined,
                          title: 'Unable to load energy reports',
                          message: _provider.error!,
                          onRetry: _provider.loadEnergyIssues,
                        );
                      }
                      if (_provider.energyIssues.isEmpty) {
                        final hasFilters = _provider.status != null || _provider.priority != null;
                        return _statusView(
                          icon: hasFilters ? Icons.search_off : Icons.bolt_rounded,
                          title: hasFilters
                              ? 'No matching energy reports'
                              : 'No energy reports yet',
                          message: hasFilters
                              ? 'Try adjusting your search terms or filters.'
                              : 'Report power outages, broken streetlights, or electrical hazards.',
                          buttonLabel: hasFilters ? 'Clear filters' : 'Submit Energy Report',
                          onRetry: hasFilters ? _clearAllFilters : _openReportSheet,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _provider.loadEnergyIssues,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                          itemCount: _provider.energyIssues.length,
                          itemBuilder: (context, index) {
                            final issue = _provider.energyIssues[index];
                            return EnergyIssueCard(
                              issue: issue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EnergyIssueDetailsScreen(
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
            _statItem('Total Reports', total, AppColors.warning, Icons.assignment_outlined, cardWidth),
            const SizedBox(width: spacing),
            _statItem('Active / Open', active, AppColors.error, Icons.pending_actions_rounded, cardWidth),
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