import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../providers/energy_water_provider.dart';
import '../widgets/energy_issue_card.dart';
import 'energy_issue_details_screen.dart';

class EnergyProblemsScreen extends StatefulWidget {
  const EnergyProblemsScreen({super.key});

  @override
  State<EnergyProblemsScreen> createState() => _EnergyProblemsScreenState();
}

class _EnergyProblemsScreenState extends State<EnergyProblemsScreen> {
  final EnergyWaterProvider _provider = EnergyWaterProvider();

  static const _statuses = ['reported', 'in_progress', 'resolved'];
  static const _priorities = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _provider.loadEnergyIssues();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Energy Problems')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: _provider.setSearch,
              decoration: const InputDecoration(
                hintText: 'Search energy reports',
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
                      _provider.status == s,
                      () => _provider
                          .setStatus(_provider.status == s ? null : s),
                    ),
                  for (final p in _priorities)
                    _filterChip(
                      p,
                      _provider.priority == p,
                      () => _provider
                          .setPriority(_provider.priority == p ? null : p),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _provider,
              builder: (context, _) {
                if (_provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_provider.error != null) {
                  return Center(
                    child: Text(
                      _provider.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                if (_provider.energyIssues.isEmpty) {
                  return const Center(
                    child: Text(
                      'No energy reports found',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                
return ListView.builder(
  padding: const EdgeInsets.all(8),
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