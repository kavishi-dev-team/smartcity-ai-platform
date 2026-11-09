import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../reporting/screens/report_details_screen.dart';

class AIAnalysisResultsScreen extends StatefulWidget {
  final int? initialIssueId;

  const AIAnalysisResultsScreen({super.key, this.initialIssueId});

  @override
  State<AIAnalysisResultsScreen> createState() =>
      _AIAnalysisResultsScreenState();
}

class _AIAnalysisResultsScreenState extends State<AIAnalysisResultsScreen> {
  late final TextEditingController _issueIdController;
  Map<String, dynamic>? _analysis;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _issueIdController = TextEditingController(
      text: (widget.initialIssueId ?? 1).toString(),
    );
    _runAnalysis(reanalyze: false);
  }

  @override
  void dispose() {
    _issueIdController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis({required bool reanalyze}) async {
    final issueId = int.tryParse(_issueIdController.text.trim());
    if (issueId == null || issueId <= 0) {
      setState(() => _error = 'Enter a valid Issue ID.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      http.Response response;
      if (reanalyze) {
        response = await http.post(
          Uri.parse('${AppConfig.apiBaseUrl}/ai/analyze-issue/$issueId'),
        );
      } else {
        response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/ai/issues/$issueId/analysis'),
        );
        if (response.statusCode == 404) {
          response = await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/ai/analyze-issue/$issueId'),
          );
        }
      }

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _analysis = decoded;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load AI analysis for Issue #$issueId ($e)';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _analysis;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Issue Analysis Inspector'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _issueIdController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Issue ID',
                              prefixIcon: Icon(Icons.tag),
                            ),
                            onSubmitted: (_) => _runAnalysis(reanalyze: false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _runAnalysis(reanalyze: false),
                          icon: const Icon(Icons.search),
                          label: const Text('Load'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _runAnalysis(reanalyze: true),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Run AI'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  )
                else if (data != null) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'AI Analysis • Issue #${data['issue_id']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReportDetailsScreen(
                                      issueId: data['issue_id'] as int,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Open Issue'),
                              ),
                            ],
                          ),
                          const Divider(height: 22),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  'Category: ${(data['category'] ?? '').toString().toUpperCase()}',
                                ),
                              ),
                              Chip(
                                label: Text(
                                  'Confidence: ${(((data['category_confidence'] as num?) ?? 0.9) * 100).toStringAsFixed(0)}%',
                                ),
                              ),
                              Chip(
                                label: Text(
                                  'Priority: ${(data['priority'] ?? '').toString().toUpperCase()}',
                                ),
                              ),
                              Chip(
                                label: Text(
                                  data['is_duplicate'] == true
                                      ? 'Possible Duplicate'
                                      : 'Unique Report',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'AI Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['summary']?.toString() ?? '',
                            style: const TextStyle(
                              color: AppColors.text,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Matched Keywords',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final kw
                                  in (data['matched_keywords'] as List<dynamic>? ??
                                      []))
                                Chip(label: Text(kw.toString())),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
