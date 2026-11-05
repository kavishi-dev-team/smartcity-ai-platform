import '../../analytics/screens/analytics_statistics_screen.dart';
import 'package:flutter/material.dart';
import '../providers/priority_issue_provider.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() =>
      _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<DashboardProvider>().loadOfficerDashboard();
    context.read<PriorityIssueProvider>().loadIssues();
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0B1220),
        Color(0xFF14243A),
        Color(0xFF1B365D),
      ],
    ),
  ),
  child: SafeArea(

            child: Consumer<DashboardProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 45,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: provider.loadOfficerDashboard,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final dashboard = provider.officerDashboard;

                if (dashboard == null) {
                  return const Center(
                    child: Text(
                      'No dashboard data available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final stats = dashboard.statistics;

                return RefreshIndicator(
                  onRefresh: provider.loadOfficerDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),

                      const Text(
                        'City Operations Overview',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Monitor and manage city issues',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 18),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          _statCard(
                            'Total Issues',
                            stats.total,
                            Colors.blue,
                            Icons.assignment_rounded,
                          ),
                          _statCard(
                            'Pending',
                            stats.pending,
                            Colors.orange,
                            Icons.pending_actions_rounded,
                          ),
                          _statCard(
                            'High Priority',
                            stats.highPriority,
                            Colors.red,
                            Icons.priority_high_rounded,
                          ),
                          _statCard(
                            'In Progress',
                            stats.inProgress,
                            Colors.purple,
                            Icons.sync_rounded,
                          ),
                          _statCard(
                            'Resolved',
                            stats.resolved,
                            Colors.green,
                            Icons.check_circle_rounded,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Card(
                        color: const Color(0xFF21618C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.analytics_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          title: const Text(
                            'Analytics & Statistics',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'View city reports and performance',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AnalyticsStatisticsScreen(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),
                     const Text(
  'AI Priority Issues',
  style: TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
),
const SizedBox(height: 12),

Consumer<PriorityIssueProvider>(
  builder: (context, filterProvider, child) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: filterProvider.selectedPriority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: ['high', 'medium', 'low']
                .map((v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase())))
                .toList(),
            onChanged: (value) => filterProvider.applyFilters(
              priority: value,
              category: filterProvider.selectedCategory,
              status: filterProvider.selectedStatus,
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: filterProvider.selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Road', 'Waste', 'Water', 'Electricity']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (value) => filterProvider.applyFilters(
              priority: filterProvider.selectedPriority,
              category: value,
              status: filterProvider.selectedStatus,
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: filterProvider.selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: ['pending', 'in_progress', 'resolved']
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (value) => filterProvider.applyFilters(
              priority: filterProvider.selectedPriority,
              category: filterProvider.selectedCategory,
              status: value,
            ),
          ),
          TextButton(
            onPressed: filterProvider.clearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  },
),


Consumer<PriorityIssueProvider>(
  builder: (context, priorityProvider, child) {
    if (priorityProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (priorityProvider.error != null) {
      return Text(
        priorityProvider.error!,
        style: const TextStyle(color: Colors.white),
      );
    }

    if (priorityProvider.issues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'No AI-prioritized issues available.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      children: priorityProvider.issues
          .take(5)
          .map(
            (issue) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                ),
                title: Text(issue.title),
                subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('${issue.category} • ${issue.status}'),
    const SizedBox(height: 6),
    Text('AI Suggested: ${issue.aiPriority.toUpperCase()}'),
    Text('Officer Final: ${issue.finalPriority.toUpperCase()}'),
    if (issue.reviewStatus != null)
      Text('Review: ${issue.reviewStatus!.toUpperCase()}'),
  ],
),
              ),
            ),
          )
          .toList(),
    );
  },
),

const SizedBox(height: 28),


                      const Text(
                        'Recent Issues',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (dashboard.recentIssues.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 42,
                                color: Colors.blueGrey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No recent issues available.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...dashboard.recentIssues.map(
                          (issue) => _issueCard(issue),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF123C69),
            Color(0xFF21618C),
            Color(0xFF2980B9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMART CITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Officer Management Portal',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.location_city_rounded,
            color: Colors.white,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    int value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _issueCard(DashboardIssue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.report_problem_rounded,
            color: Colors.deepOrange,
            size: 25,
          ),
        ),
        title: Text(
          issue.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${issue.category} • ${issue.status} • ${issue.priority}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
