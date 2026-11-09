import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';
import 'package:smart_city_app/features/auth/providers/auth_provider.dart';
import 'package:smart_city_app/features/reporting/widgets/quick_issue_report_sheet.dart';

import '../providers/energy_water_provider.dart';
import '../widgets/water_issue_card.dart';
import 'water_issue_details_screen.dart';
import 'water_leakage_map_screen.dart';
class WaterLeakageReportsScreen extends StatefulWidget {
  const WaterLeakageReportsScreen({super.key});

  @override
  State<WaterLeakageReportsScreen> createState() =>
      _WaterLeakageReportsScreenState();
}

class _WaterLeakageReportsScreenState
    extends State<WaterLeakageReportsScreen> {
  final EnergyWaterProvider _provider = EnergyWaterProvider();

  static const _statuses = ['reported', 'in_progress', 'resolved'];
  static const _severities = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      _provider.reportedBy = (user != null && user.isCitizen) ? user.id : null;
      _provider.loadLeakageIssues();
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  void _openReportSheet() {
    QuickIssueReportSheet.show(
      context,
      initialCategory: 'water',
      initialSubcategory: 'leakage',
      onSubmitted: _provider.loadLeakageIssues,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Leakage Reports'),
        actions: [
          IconButton(
            tooltip: 'Submit Leakage Report',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _openReportSheet,
          ),
          IconButton(
            tooltip: 'View Map',
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WaterLeakageMapScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openReportSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Report Leakage',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: _provider.setLeakageSearch,
              decoration: const InputDecoration(
                hintText: 'Search leakage reports',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _provider,
            builder: (context, _) => SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final s in _statuses)
                    _filterChip(
                      s.replaceAll('_', ' '),
                      _provider.leakageStatus == s,
                      () => _provider.setLeakageStatus(
                          _provider.leakageStatus == s ? null : s),
                    ),
                  for (final v in _severities)
                    _filterChip(
                      '$v severity',
                      _provider.leakageSeverity == v,
                      () => _provider.setLeakageSeverity(
                          _provider.leakageSeverity == v ? null : v),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _provider,
              builder: (context, _) {
                if (_provider.leakageLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_provider.leakageError != null) {
                  return Center(
                    child: Text(
                      _provider.leakageError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                if (_provider.leakageIssues.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.plumbing_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No leakage reports found',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Report pipe bursts, roadside water leaks, or valve leaks immediately.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _openReportSheet,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Report Water Leakage'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
  padding: const EdgeInsets.all(8),
  itemCount: _provider.leakageIssues.length,
  itemBuilder: (context, index) {
    final issue = _provider.leakageIssues[index];

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
);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.lightBlue,
      ),
    );
  }
}