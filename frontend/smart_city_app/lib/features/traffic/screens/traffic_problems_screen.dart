import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/traffic_provider.dart';
import '../services/traffic_service.dart';
import '../widgets/traffic_filter_sheet.dart';
import '../widgets/traffic_issue_card.dart';
import 'traffic_problem_details_screen.dart';
import 'traffic_incident_map_screen.dart';

class TrafficProblemsScreen extends StatefulWidget {
  final TrafficService? service;

  const TrafficProblemsScreen({super.key, this.service});

  @override
  State<TrafficProblemsScreen> createState() => _TrafficProblemsScreenState();
}

class _TrafficProblemsScreenState extends State<TrafficProblemsScreen> {
  late final TrafficService _service;
  late final bool _ownsService;
  late final TrafficProvider _provider;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? TrafficService();
    _provider = TrafficProvider(_service);
    _provider.refresh();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _provider.dispose();
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  void _onSearch(String term) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _provider.updateSearch(term);
    });
  }

  Future<void> _openFilters() async {
    final value = await showModalBottomSheet<TrafficFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TrafficFilterSheet(initial: _provider.filters),
    );
    if (value != null && mounted) _provider.applyFilters(value);
  }

  void _clearSearch() {
    _searchTimer?.cancel();
    _searchController.clear();
    _provider.updateSearch('');
  }

  void _clearAll() {
    _searchTimer?.cancel();
    _searchController.clear();
    _provider.clearFilters();
  }

  void _openIssue(int id) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => TrafficProblemDetailsScreen(issueId: id, service: _service),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traffic Problems')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                color: AppColors.background,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('City Traffic Reports',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.text)),
                  const SizedBox(height: 5),
                  const Text('Explore reported road and traffic problems.',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Search traffic reports...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(animation: _provider, builder: (context, _) => Row(children: [
                    OutlinedButton.icon(
                      onPressed: _openFilters,
                      icon: const Icon(Icons.tune),
                      label: Text(_provider.filters.isActive ? 'Filters applied' : 'Filters'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TrafficIncidentMapScreen(service: _service),
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Map'),
                    ),
                    const SizedBox(width: 6),
                    if (_provider.filters.isActive)
                      IconButton(tooltip: 'Clear filters', onPressed: _clearAll, icon: const Icon(Icons.filter_alt_off_outlined)),
                    const Spacer(),
                    if (!_provider.loading)
                      Text('${_provider.total} reports',
                          style: const TextStyle(color: AppColors.muted)),
                  ])),
                ]),
              ),
              Expanded(
                child: AnimatedBuilder(animation: _provider, builder: (context, _) {
                  if (_provider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_provider.error != null && _provider.issues.isEmpty) {
                    return _StatusView(
                      icon: Icons.wifi_off_outlined,
                      title: 'Unable to load traffic reports',
                      message: _provider.error!,
                      onRetry: _provider.refresh,
                    );
                  }
                  if (_provider.issues.isEmpty) {
                    return _StatusView(
                      icon: Icons.search_off,
                      title: 'No traffic reports found',
                      message: 'Try a different search term or clear filters.',
                      onRetry: _clearAll,
                      buttonLabel: 'Clear filters',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _provider.refresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
                      itemCount: _provider.issues.length + (_provider.hasMore || _provider.error != null ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _provider.issues.length) {
                          if (_provider.error != null) {
                            return Column(children: [
                              Text(_provider.error!, textAlign: TextAlign.center),
                              TextButton(onPressed: _provider.loadMore, child: const Text('Retry loading more')),
                            ]);
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: _provider.loadingMore
                                  ? const CircularProgressIndicator()
                                  : OutlinedButton(
                                      onPressed: _provider.loadMore,
                                      child: const Text('Load more reports'),
                                    ),
                            ),
                          );
                        }
                        final issue = _provider.issues[index];
                        return TrafficIssueCard(issue: issue, onTap: () => _openIssue(issue.id));
                      },
                    ),
                  );
                }),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  final String buttonLabel;

  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    this.buttonLabel = 'Try again',
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 54, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: onRetry, child: Text(buttonLabel)),
          ]),
        ),
      );
}
