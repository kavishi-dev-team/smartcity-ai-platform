import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/models/priority_issue_model.dart';
import '../../dashboard/providers/priority_issue_provider.dart';
import '../../reporting/screens/report_details_screen.dart';
import '../../traffic/screens/traffic_status_management_screen.dart';
import 'ai_analysis_results_screen.dart';

class AIPrioritizedIssuesScreen extends StatefulWidget {
  const AIPrioritizedIssuesScreen({super.key});

  @override
  State<AIPrioritizedIssuesScreen> createState() =>
      _AIPrioritizedIssuesScreenState();
}

class _AIPrioritizedIssuesScreenState extends State<AIPrioritizedIssuesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PriorityIssueProvider>().loadIssues();
    });
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Future<void> _showReviewDialog(PriorityIssue issue) async {
    String selectedPriority = issue.finalPriority.toLowerCase();
    if (!['low', 'medium', 'high'].contains(selectedPriority)) {
      selectedPriority = 'high';
    }
    final noteController = TextEditingController();
    final reviewerId = context.read<AuthProvider>().user?.id ?? 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Review Priority • Issue #${issue.issueId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Recommended: ${issue.aiPriority.toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Final Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('HIGH')),
                  DropdownMenuItem(value: 'medium', child: Text('MEDIUM')),
                  DropdownMenuItem(value: 'low', child: Text('LOW')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedPriority = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Review Note (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Review'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/issues/${issue.issueId}/priority-review?reviewed_by=$reviewerId',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'final_priority': selectedPriority,
          'review_note': noteController.text.trim().isEmpty
              ? null
              : noteController.text.trim(),
        }),
      );
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Priority review saved!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.read<PriorityIssueProvider>().loadIssues();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to review priority: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriorityIssueProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Prioritized Issues'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: provider.isLoading ? null : provider.loadIssues,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: provider.selectedPriority,
                                decoration: const InputDecoration(
                                  labelText: 'Priority',
                                ),
                                items: ['high', 'medium', 'low']
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(v.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => provider.applyFilters(
                                  priority: value,
                                  category: provider.selectedCategory,
                                  status: provider.selectedStatus,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: provider.selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                ),
                                items: [
                                  'traffic',
                                  'waste',
                                  'water',
                                  'energy',
                                  'safety',
                                  'complaint',
                                ]
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(v.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => provider.applyFilters(
                                  priority: provider.selectedPriority,
                                  category: value,
                                  status: provider.selectedStatus,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: provider.selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                ),
                                items: [
                                  'reported',
                                  'assigned',
                                  'in_progress',
                                  'resolved',
                                ]
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(
                                          v.replaceAll('_', ' ').toUpperCase(),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => provider.applyFilters(
                                  priority: provider.selectedPriority,
                                  category: provider.selectedCategory,
                                  status: value,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            TextButton.icon(
                              onPressed: provider.clearFilters,
                              icon: const Icon(Icons.filter_alt_off_outlined),
                              label: const Text('Reset'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null
                        ? Center(
                            child: Text(
                              provider.error!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          )
                        : provider.issues.isEmpty
                            ? const Center(
                                child: Text(
                                  'No AI-prioritized issues match the selected filters.',
                                  style: TextStyle(color: AppColors.muted),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: provider.loadIssues,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    0,
                                    14,
                                    24,
                                  ),
                                  itemCount: provider.issues.length,
                                  itemBuilder: (context, index) {
                                    final item = provider.issues[index];
                                    final color =
                                        _priorityColor(item.finalPriority);
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                      alpha: 0.14,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      20,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'FINAL: ${item.finalPriority.toUpperCase()}',
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      20,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'AI: ${item.aiPriority.toUpperCase()}',
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '#${item.issueId} • ${item.category.toUpperCase()}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.muted,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              item.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.text,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (item.priorityExplanation !=
                                                null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'AI Rationale: ${item.priorityExplanation}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.primaryDark,
                                                ),
                                              ),
                                            ],
                                            if (item.matchedKeywords
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: item.matchedKeywords
                                                    .map(
                                                      (kw) => Chip(
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        label: Text(
                                                          kw,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ReportDetailsScreen(
                                                        issueId: item.issueId,
                                                      ),
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.visibility_outlined,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'View Report',
                                                  ),
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          AIAnalysisResultsScreen(
                                                        initialIssueId:
                                                            item.issueId,
                                                      ),
                                                    ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.auto_awesome_outlined,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'AI Analysis',
                                                  ),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _showReviewDialog(item),
                                                  icon: const Icon(
                                                    Icons.tune_rounded,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Review Priority',
                                                  ),
                                                ),
                                                FilledButton.tonalIcon(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.lightBlue,
                                                    foregroundColor:
                                                        AppColors.primaryDark,
                                                  ),
                                                  onPressed: () async {
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute<void>(
                                                        builder: (_) =>
                                                            TrafficStatusManagementScreen(
                                                          issueId: item.issueId,
                                                          categoryLabel: item
                                                              .category
                                                              .toUpperCase(),
                                                        ),
                                                      ),
                                                    );
                                                    if (mounted) {
                                                      provider.loadIssues();
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons
                                                        .manage_accounts_rounded,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Manage Case',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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