
import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../providers/energy_water_provider.dart';
import '../widgets/water_issue_card.dart';
import 'water_issue_details_screen.dart';

class WaterProblemsScreen extends StatefulWidget {
  const WaterProblemsScreen({super.key});

  @override
  State<WaterProblemsScreen> createState() =>
      _WaterProblemsScreenState();
}

class _WaterProblemsScreenState extends State<WaterProblemsScreen> {
  final EnergyWaterProvider _provider = EnergyWaterProvider();

  static const _statuses = [
    'reported',
    'in_progress',
    'resolved',
  ];

  static const _priorities = [
    'low',
    'medium',
    'high',
  ];

  @override
  void initState() {
    super.initState();
    _provider.loadWaterIssues();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Problems'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: _provider.setWaterSearch,
              decoration: const InputDecoration(
                hintText: 'Search water reports',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Horizontally Scrollable Filters
          ListenableBuilder(
            listenable: _provider,
            builder: (context, _) {
              return SizedBox(
                height: 52,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      // Status Filters
                      for (final s in _statuses)
                        _filterChip(
                          s.replaceAll('_', ' '),
                          _provider.waterStatus == s,
                          () {
                            _provider.setWaterStatus(
                              _provider.waterStatus == s
                                  ? null
                                  : s,
                            );
                          },
                        ),

                      // Priority Filters
                      for (final p in _priorities)
                        _filterChip(
                          p,
                          _provider.waterPriority == p,
                          () {
                            _provider.setWaterPriority(
                              _provider.waterPriority == p
                                  ? null
                                  : p,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Water Reports
          Expanded(
            child: ListenableBuilder(
              listenable: _provider,
              builder: (context, _) {
                if (_provider.waterLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_provider.waterError != null) {
                  return Center(
                    child: Text(
                      _provider.waterError!,
                      style: const TextStyle(
                        color: AppColors.error,
                      ),
                    ),
                  );
                }

                if (_provider.waterIssues.isEmpty) {
                  return const Center(
                    child: Text(
                      'No water reports found',
                      style: TextStyle(
                        color: AppColors.muted,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _provider.waterIssues.length,
                  itemBuilder: (context, index) {
                    final issue = _provider.waterIssues[index];

                    return WaterIssueCard(
                      issue: issue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WaterIssueDetailsScreen(
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

  // Filter Chip Widget
  Widget _filterChip(
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
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
