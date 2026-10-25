import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../providers/energy_water_provider.dart';
import '../widgets/water_issue_card.dart';

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
    _provider.loadLeakageIssues();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Water Leakage Reports')),
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
                  return const Center(
                    child: Text(
                      'No leakage reports found',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _provider.leakageIssues.length,
                  itemBuilder: (context, index) => WaterIssueCard(
                    issue: _provider.leakageIssues[index],
                  ),
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