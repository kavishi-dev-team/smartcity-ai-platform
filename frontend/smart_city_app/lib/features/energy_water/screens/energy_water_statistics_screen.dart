import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../providers/energy_water_provider.dart';
import '../widgets/statistics_chart.dart';

class EnergyWaterStatisticsScreen extends StatefulWidget {
  const EnergyWaterStatisticsScreen({super.key});

  @override
  State<EnergyWaterStatisticsScreen> createState() =>
      _EnergyWaterStatisticsScreenState();
}

class _EnergyWaterStatisticsScreenState
    extends State<EnergyWaterStatisticsScreen> {
  final EnergyWaterProvider _provider = EnergyWaterProvider();

  @override
  void initState() {
    super.initState();
    _provider.loadStatistics();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Energy & Water Statistics')),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          final stats = _provider.stats;
          final isWater = _provider.statsCategory == 'water';
          final color = isWater ? AppColors.cyan : AppColors.warning;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'energy', label: Text('Energy')),
                  ButtonSegment(value: 'water', label: Text('Water')),
                ],
                selected: {_provider.statsCategory},
                onSelectionChanged: (s) =>
                    _provider.setStatsCategory(s.first),
              ),
              const SizedBox(height: 16),
              if (_provider.statsLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_provider.statsError != null)
                Center(
                  child: Text(
                    _provider.statsError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                )
              else if (stats != null) ...[
                Row(
                  children: [
                    Expanded(
                        child: _summary(
                            'Total', stats.totalReports, AppColors.primary)),
                    Expanded(
                        child: _summary(
                            'Resolved', stats.resolvedReports, AppColors.success)),
                  ],
                ),
                const SizedBox(height: 8),
                StatisticsChart(
                    title: 'Reports by category',
                    data: stats.byCategory,
                    color: color),
                StatisticsChart(
                    title: 'Reports by status',
                    data: stats.byStatus,
                    color: AppColors.primary),
                StatisticsChart(
                    title: 'Monthly trend',
                    data: stats.monthlyTrend,
                    color: color),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _summary(String label, int value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}