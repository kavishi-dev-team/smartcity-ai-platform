import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../reporting/screens/report_details_screen.dart';

class ComplaintClustersScreen extends StatefulWidget {
  const ComplaintClustersScreen({super.key});

  @override
  State<ComplaintClustersScreen> createState() =>
      _ComplaintClustersScreenState();
}

class _ComplaintClustersScreenState extends State<ComplaintClustersScreen> {
  List<Map<String, dynamic>> _clusters = [];
  bool _loading = true;
  String? _error;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadClusters();
  }

  Future<void> _loadClusters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = <String, String>{};
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        query['category'] = _selectedCategory!;
      }
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/issue-clusters/',
      ).replace(queryParameters: query.isEmpty ? null : query);

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _clusters = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load issue clusters: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openClusterIssues(Map<String, dynamic> cluster) async {
    final clusterId = cluster['id'] as int;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse('${AppConfig.apiBaseUrl}/issue-clusters/$clusterId/issues'),
          ),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.statusCode != 200) {
              return const Center(
                child: Text('Could not load cluster member issues.'),
              );
            }
            final body =
                jsonDecode(snapshot.data!.body) as Map<String, dynamic>;
            final issues = (body['issues'] as List<dynamic>? ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  cluster['name']?.toString() ?? 'Cluster #$clusterId',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cluster['description']?.toString() ?? '',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const Divider(height: 24),
                Text(
                  'Grouped Reports (${issues.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                for (final issue in issues)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        issue['title']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${(issue['category'] ?? '').toString().toUpperCase()} • ${(issue['status'] ?? '').toString().toUpperCase()} • Similarity: ${(((issue['similarity_score'] as num?) ?? 0.85) * 100).toStringAsFixed(0)}%',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailsScreen(
                              issueId: issue['id'] as int,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Complaint & Issue Clusters'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadClusters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Category',
                    prefixIcon: Icon(Icons.hub_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Categories')),
                    DropdownMenuItem(value: 'traffic', child: Text('Traffic')),
                    DropdownMenuItem(value: 'waste', child: Text('Waste')),
                    DropdownMenuItem(value: 'water', child: Text('Water')),
                    DropdownMenuItem(value: 'energy', child: Text('Energy')),
                    DropdownMenuItem(value: 'safety', child: Text('Safety')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                    _loadClusters();
                  },
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          )
                        : _clusters.isEmpty
                            ? const Center(
                                child: Text(
                                  'No issue clusters found.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadClusters,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    0,
                                    14,
                                    24,
                                  ),
                                  itemCount: _clusters.length,
                                  itemBuilder: (context, index) {
                                    final c = _clusters[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(16),
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          child: Text(
                                            '${c['issue_count'] ?? 0}',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          c['name']?.toString() ?? 'Cluster',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (c['description'] != null)
                                                Text(
                                                  c['description'].toString(),
                                                  style: const TextStyle(
                                                    color: AppColors.muted,
                                                  ),
                                                ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 8,
                                                children: [
                                                  Chip(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    label: Text(
                                                      (c['category'] ?? 'city')
                                                          .toString()
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                  if (c['city'] != null)
                                                    Chip(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      label: Text(
                                                        c['city'].toString(),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                        ),
                                        onTap: () => _openClusterIssues(c),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}