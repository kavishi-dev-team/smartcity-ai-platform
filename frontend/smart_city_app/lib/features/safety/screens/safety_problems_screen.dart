import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reporting/widgets/issue_location_tracker_card.dart';
import '../../reporting/widgets/quick_issue_report_sheet.dart';
import '../models/safety_issue_model.dart';
import '../providers/safety_provider.dart';
import '../widgets/safety_filter_sheet.dart';
import '../widgets/safety_issue_card.dart';
import 'safety_alerts_screen.dart';
import 'safety_problem_details_screen.dart';

/// Entry point for the Safety Problems feature.
/// Creates the provider, so it can be opened from anywhere:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyProblemsScreen()));
class SafetyProblemsScreen extends StatelessWidget {
  const SafetyProblemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final reportedBy = (user != null && user.isCitizen) ? user.id : null;
    return ChangeNotifierProvider(
      key: ValueKey('safety-problems-$reportedBy'),
      create: (_) => SafetyProvider(reportedBy: reportedBy)..loadProblemsScreen(),
      child: const _ProblemsView(),
    );
  }
}

class _ProblemsView extends StatefulWidget {
  const _ProblemsView();

  @override
  State<_ProblemsView> createState() => _ProblemsViewState();
}

class _ProblemsViewState extends State<_ProblemsView> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh the clear (x) button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<SafetyProvider>().setProblemSearch(value);
    });
  }

  void _openDetails(SafetyIssue issue) {
    final provider = context.read<SafetyProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: SafetyProblemDetailsScreen(issue: issue),
        ),
      ),
    );
  }

  void _openAlerts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SafetyAlertsScreen()),
    );
  }

  void _openReportSheet(SafetyProvider p) {
    QuickIssueReportSheet.show(
      context,
      initialCategory: 'safety',
      onSubmitted: p.loadProblemsScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SafetyProvider>();

    final totalCount = p.problemsTotal > 0 ? p.problemsTotal : p.problems.length;
    final resolvedCount = p.problems
        .where((i) => ['resolved', 'closed'].contains(i.status.toLowerCase()))
        .length;
    final activeCount = p.problems
        .where((i) => !['resolved', 'closed'].contains(i.status.toLowerCase()))
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Problems'),
        actions: [
          IconButton(
            tooltip: 'Track Safety Locations on Map',
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const DomainLocationTrackerScreen(category: 'safety'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Submit Safety Report',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _openReportSheet(p),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => p.loadProblemsScreen(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openReportSheet(p),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Safety Report',
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
                        'City Safety Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Inspect public safety hazards, security concerns, and community reports.',
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
                        controller: _search,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          _debounce?.cancel();
                          p.setProblemSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search safety reports...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                    p.setProblemSearch('');
                                  },
                                ),
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
                            onPressed: () => _openReportSheet(p),
                            icon: const Icon(Icons.add_task_rounded, size: 18),
                            label: const Text('Report Safety Issue'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => showSafetyFilterSheet(context, p),
                            icon: const Icon(Icons.tune),
                            label: Text(
                              p.hasProblemFilters ? 'Filters applied' : 'Filters',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const DomainLocationTrackerScreen(
                                    category: 'safety',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Live Map'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openAlerts,
                            icon: const Icon(Icons.campaign_outlined),
                            label: const Text('Safety Alerts'),
                          ),
                          if (p.hasProblemFilters)
                            IconButton(
                              tooltip: 'Clear filters',
                              onPressed: p.clearProblemFilters,
                              icon: const Icon(Icons.filter_alt_off_outlined),
                            ),
                          if (!p.isLoadingProblems)
                            Text(
                              '$totalCount reports',
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
                  child: p.isLoadingProblems && p.problems.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : p.problemsError != null && p.problems.isEmpty
                          ? _statusView(
                              icon: Icons.wifi_off_outlined,
                              title: 'Unable to load safety reports',
                              message: p.problemsError!,
                              onRetry: () => p.loadProblemsScreen(),
                            )
                          : p.problems.isEmpty
                              ? _statusView(
                                  icon: p.hasProblemFilters
                                      ? Icons.search_off
                                      : Icons.shield_outlined,
                                  title: p.hasProblemFilters
                                      ? 'No matching safety reports'
                                      : 'No safety reports yet',
                                  message: p.hasProblemFilters
                                      ? 'Try adjusting your search terms or filters.'
                                      : 'Report road hazards, street lighting failures, vandalism, or disturbances.',
                                  buttonLabel: p.hasProblemFilters
                                      ? 'Clear filters'
                                      : 'Submit Safety Report',
                                  onRetry: p.hasProblemFilters
                                      ? p.clearProblemFilters
                                      : () => _openReportSheet(p),
                                )
                              : RefreshIndicator(
                                  onRefresh: p.loadProblemsScreen,
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                                    itemCount: p.problems.length +
                                        (p.problemsTotalPages > 1 ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index >= p.problems.length) {
                                        return _buildPagingFooter(p);
                                      }
                                      final issue = p.problems[index];
                                      return SafetyIssueRow(
                                        issue: issue,
                                        onTap: () => _openDetails(issue),
                                        onUpdated: p.loadProblemsScreen,
                                      );
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
            _statItem('Total Reports', total, AppColors.error, Icons.assignment_outlined, cardWidth),
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

  Widget _buildPagingFooter(SafetyProvider p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: p.problemsPage > 1 ? () => p.goToProblemsPage(p.problemsPage - 1) : null,
            child: const Text('Previous'),
          ),
          const SizedBox(width: 12),
          Text(
            'Page ${p.problemsPage} of ${p.problemsTotalPages}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: p.problemsPage < p.problemsTotalPages ? () => p.goToProblemsPage(p.problemsPage + 1) : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
