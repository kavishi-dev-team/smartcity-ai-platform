import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/safety_issue_model.dart';
import '../providers/safety_provider.dart';
import '../utils/safety_formatters.dart';
import '../widgets/safety_filter_sheet.dart';
import '../widgets/safety_issue_card.dart';
import '../widgets/safety_message_view.dart';
import '../widgets/safety_stat_card.dart';
import 'safety_alerts_screen.dart';
import 'safety_problem_details_screen.dart';

/// Entry point for the Safety Problems feature.
/// Creates the provider, so it can be opened from anywhere:
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyProblemsScreen()));
class SafetyProblemsScreen extends StatelessWidget {
  const SafetyProblemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SafetyProvider()..loadProblemsScreen(),
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

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SafetyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety'),
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => p.loadProblemsScreen(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: p.loadProblemsScreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'View verified public safety reports and community guidance.',
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          // TODO: export belongs to the analytics module.
                          onPressed: () => _snack('Export will be available soon.'),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Export'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: AppColors.text,
                            backgroundColor: AppColors.card,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          // TODO: open the shared "Report a Problem" screen (features/reporting).
                          onPressed: () => _snack(
                            'The report form comes from the shared reporting module.',
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Create request'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStats(p),
                  const SizedBox(height: 16),
                  _buildOverview(p),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- 3 stat cards ----------------
  Widget _buildStats(SafetyProvider p) {
    final s = p.summary;
    final percent = s?.resolvedInSlaPercent;
    final cards = <Widget>[
      SafetyStatCard(
        icon: Icons.shield_outlined,
        label: 'Active alerts',
        value: s == null ? '-' : '${s.activeAlerts}',
        accent: AppColors.primary,
        onTap: _openAlerts,
      ),
      SafetyStatCard(
        icon: Icons.assignment_outlined,
        label: 'Open reports',
        value: s == null ? '-' : '${s.openReports}',
        accent: AppColors.cyan,
      ),
      SafetyStatCard(
        icon: Icons.check_circle_outline,
        label: 'Resolved in SLA',
        value: percent == null ? '-' : '$percent%',
        accent: AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  // ---------------- overview card (search + table + paging) ----------------
  Widget _buildOverview(SafetyProvider p) {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: AppColors.muted,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety problems overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                if (p.problemsUpdatedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Updated ${formatRelative(p.problemsUpdatedAt!)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          _debounce?.cancel();
                          p.setProblemSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search records...',
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
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => showSafetyFilterSheet(context, p),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Badge(
                          isLabelVisible: p.hasProblemFilters,
                          child: const Icon(
                            Icons.filter_list,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (p.hasProblemFilters)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: p.clearProblemFilters,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Clear filters'),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: AppColors.primary.withValues(alpha: 0.06),
            padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('REFERENCE / NAME', style: headerStyle)),
                Expanded(flex: 5, child: Text('TYPE / STATUS', style: headerStyle)),
                SizedBox(width: 40),
              ],
            ),
          ),
          SizedBox(
            height: 3,
            child: p.isLoadingProblems ? const LinearProgressIndicator() : null,
          ),
          _buildRows(p),
          const Divider(height: 1),
          _buildFooter(p),
        ],
      ),
    );
  }

  Widget _buildRows(SafetyProvider p) {
    if (p.isLoadingProblems && p.problems.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (p.problemsError != null) {
      return SizedBox(
        height: 260,
        child: SafetyMessageView(
          icon: Icons.cloud_off,
          message: p.problemsError!,
          actionLabel: 'Try again',
          onAction: () => p.loadProblemsScreen(),
        ),
      );
    }
    if (p.problems.isEmpty) {
      return const SizedBox(
        height: 220,
        child: SafetyMessageView(
          icon: Icons.search_off,
          message: 'No records found.',
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < p.problems.length; i++) ...[
          SafetyIssueRow(
            issue: p.problems[i],
            onTap: () => _openDetails(p.problems[i]),
          ),
          if (i < p.problems.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _buildFooter(SafetyProvider p) {
    Widget pageButton(String label, bool enabled, VoidCallback onTap) {
      return OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Text(
            'Showing ${p.problems.length} of ${p.problemsTotal} records',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              pageButton(
                'Previous',
                p.problemsPage > 1,
                () => p.goToProblemsPage(p.problemsPage - 1),
              ),
              const SizedBox(width: 6),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${p.problemsPage}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              pageButton(
                'Next',
                p.problemsPage < p.problemsTotalPages,
                () => p.goToProblemsPage(p.problemsPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
