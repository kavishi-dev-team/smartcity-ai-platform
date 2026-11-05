
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
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _summary(
                        'Total',
                        stats.totalReports,
                        AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _summary(
                        'Resolved',
                        stats.resolvedReports,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Reports by Category
                StatisticsChart(
                  title: 'Reports by category',
                  data: stats.byCategory,
                  color: color,
                ),

                // Reports by Status
                StatisticsChart(
                  title: 'Reports by status',
                  data: stats.byStatus,
                  color: AppColors.primary,
                ),

                // Monthly Trend
                StatisticsChart(
                  title: 'Monthly trend',
                  data: stats.monthlyTrend,
                  color: color,
                ),

                const SizedBox(height: 8),

                // Area-wise Statistics
                _areaWiseStatistics(
                  stats.areaWise,
                  color,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // Summary Card
  Widget _summary(String label, int value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
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

  // Area-wise Statistics
  Widget _areaWiseStatistics(
    Map<String, int> areaWise,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Area-wise Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (areaWise.isEmpty)
              const Text(
                'No area-wise data available.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              ...areaWise.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${entry.value} reports',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: areaWise.values.reduce(
                              (a, b) => a > b ? a : b,
                            ) == 0
                            ? 0
                            : entry.value /
                                areaWise.values.reduce(
                                  (a, b) => a > b ? a : b,
                                ),
                        backgroundColor: AppColors.muted.withValues(
                          alpha: 0.2,
                        ),
                        color: color,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
