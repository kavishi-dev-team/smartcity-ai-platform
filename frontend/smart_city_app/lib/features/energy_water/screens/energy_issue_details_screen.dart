
import 'package:flutter/material.dart';
import 'package:smart_city_app/core/theme/app_colors.dart';

import '../models/energy_issue_model.dart';
import '../models/issue_details_model.dart';
import '../services/energy_water_service.dart';

class EnergyIssueDetailsScreen extends StatefulWidget {
  final EnergyIssue issue;

  const EnergyIssueDetailsScreen({
    super.key,
    required this.issue,
  });

  @override
  State<EnergyIssueDetailsScreen> createState() =>
      _EnergyIssueDetailsScreenState();
}

class _EnergyIssueDetailsScreenState
    extends State<EnergyIssueDetailsScreen> {
  final EnergyWaterService _service = EnergyWaterService();

  late Future<IssueDetails> _detailsFuture;
  late Future<List<Map<String, dynamic>>> _departmentsFuture;

  int? _selectedDepartmentId;
  bool _isAssigning = false;

  final TextEditingController _noteController =
      TextEditingController();

  // Temporary test user ID.
  // Replace with logged-in user ID after authentication.
  final int _currentUserId = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _detailsFuture =
        _service.fetchEnergyIssueDetails(widget.issue.id);

    _departmentsFuture = _service.fetchDepartments();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }


  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Future<void> _assignDepartment() async {
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department'),
        ),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      await _service.assignIssue(
        issueId: widget.issue.id,
        assignedTo: _currentUserId,
        assignedBy: _currentUserId,
        departmentId: _selectedDepartmentId!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;

      _noteController.clear();

      setState(() {
        _selectedDepartmentId = null;
        _detailsFuture =
            _service.fetchEnergyIssueDetails(widget.issue.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Issue assigned successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assignment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Report Details'),
      ),
      body: FutureBuilder<IssueDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load energy report details',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _detailsFuture =
                              _service.fetchEnergyIssueDetails(
                            widget.issue.id,
                          );
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No report details available'),
            );
          }

          final details = snapshot.data!;

          final location = [
            details.location?.address,
            details.location?.city,
          ]
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .join(', ');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      details.status.replaceAll('_', ' '),
                      AppColors.primary,
                    ),
                    _chip(
                      '${details.priority} priority',
                      _priorityColor(details.priority),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _section(
                  'Description',
                  Text(
                    details.description,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                    ),
                  ),
                ),

                // Evidence Photos
                _section(
                  'Evidence Photos',
                  details.attachments.isEmpty
                      ? _emptyMessage(
                          'No evidence photos available',
                        )
                      : Column(
                          children: details.attachments.map(
                            (attachment) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Image.network(
                                      attachment.fileUrl,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) {
                                        return const Text(
                                          'Unable to load image',
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 5),
                                    Text(attachment.fileName),
                                  ],
                                ),
                              );
                            },
                          ).toList(),
                        ),
                ),

                // Location
                _section(
                  'Location',
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.isEmpty
                            ? 'Location not available'
                            : location,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                        ),
                      ),
                      if (details.location?.latitude != null &&
                          details.location?.longitude != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Latitude: ${details.location!.latitude}',
                        ),
                        Text(
                          'Longitude: ${details.location!.longitude}',
                        ),
                      ],
                    ],
                  ),
                ),

                // AI Analysis
                _section(
                  'AI Analysis',
                  details.aiAnalysis.isEmpty
                      ? _emptyMessage(
                          'No AI analysis available yet',
                        )
                      : Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: details.aiAnalysis.map(
                            (analysis) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      analysis.analysisType,
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    if (analysis.explanation !=
                                        null)
                                      Text(
                                        analysis.explanation!,
                                      ),
                                    if (analysis.result != null)
                                      Text(
                                        'Result: ${analysis.result}',
                                      ),
                                    if (analysis.confidenceScore !=
                                        null)
                                      Text(
                                        'Confidence: ${analysis.confidenceScore}%',
                                      ),
                                  ],
                                ),
                              );
                            },
                          ).toList(),
                        ),
                ),

                // Recommended Priority
                _section(
                  'Recommended Priority',
                  _chip(
                    '${details.priority} priority',
                    _priorityColor(details.priority),
                  ),
                ),

                // Similar Reports
                _section(
                  'Similar Reports',
                  details.similarReports.isEmpty
                      ? _emptyMessage(
                          'No similar reports found',
                        )
                      : Column(
                          children:
                              details.similarReports.map((report) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.description_outlined,
                              ),
                              title: Text(report.title),
                              subtitle: Text(
                                '${report.status} • ${report.priority} priority',
                              ),
                              trailing:
                                  report.similarityScore == null
                                      ? null
                                      : Text(
                                          '${(report.similarityScore! * 100).toStringAsFixed(0)}%',
                                        ),
                            );
                          }).toList(),
                        ),
                ),

                // Responsible Department
                _section(
                  'Responsible Department',
                  Text(
                    details.department?.name ??
                        'Not assigned yet',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                    ),
                  ),
                ),

                // Department Assignment UI
                _section(
                  'Assign to Department',
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<
                          List<Map<String, dynamic>>>(
                        future: _departmentsFuture,
                        builder: (context, departmentSnapshot) {
                          if (departmentSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          if (departmentSnapshot.hasError) {
                            return Text(
                              'Failed to load departments: '
                              '${departmentSnapshot.error}',
                            );
                          }

                          final departments =
                              departmentSnapshot.data ?? [];

                          if (departments.isEmpty) {
                            return _emptyMessage(
                              'No departments available',
                            );
                          }

                          return DropdownButtonFormField<int>(
                            initialValue: _selectedDepartmentId,
                            decoration: const InputDecoration(
                              labelText: 'Select Department',
                              border: OutlineInputBorder(),
                            ),
                            items: departments.map((department) {
                              return DropdownMenuItem<int>(
                                value: department['id'] as int,
                                child: Text(
                                  department['name'].toString(),
                                ),
                              );
                            }).toList(),
                            onChanged: _isAssigning
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedDepartmentId =
                                          value;
                                    });
                                  },
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _noteController,
                        enabled: !_isAssigning,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Assignment Note (Optional)',
                          hintText:
                              'Enter assignment details...',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isAssigning
                              ? null
                              : _assignDepartment,
                          icon: _isAssigning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.assignment_turned_in),
                          label: Text(
                            _isAssigning
                                ? 'Assigning...'
                                : 'Assign Department',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Status
                _section(
                  'Current Status',
                  _chip(
                    details.status.replaceAll('_', ' '),
                    AppColors.primary,
                  ),
                ),

                // Status Timeline
                _section(
                  'Status Timeline',
                  details.statusTimeline.isEmpty
                      ? _emptyMessage(
                          'No status updates recorded yet',
                        )
                      : Column(
                          children: details.statusTimeline.map(
                            (item) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                title: Text(
                                  item.newStatus.replaceAll(
                                    '_',
                                    ' ',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (item.note != null)
                                      Text(item.note!),
                                    Text(
                                      item.createdAt
                                          .toLocal()
                                          .toString()
                                          .substring(0, 16),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ).toList(),
                        ),
                ),

                // Reported Date
                _section(
                  'Reported',
                  Text(
                    details.createdAt
                        .toLocal()
                        .toString()
                        .substring(0, 16),
                    style: const TextStyle(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyMessage(String message) {
    return Text(
      message,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 14,
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
