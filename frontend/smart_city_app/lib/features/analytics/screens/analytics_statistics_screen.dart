import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/analytics_provider.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/statistics_card.dart';

class AnalyticsStatisticsScreen extends StatefulWidget {
  const AnalyticsStatisticsScreen({super.key});

  @override
  State<AnalyticsStatisticsScreen> createState() =>
      _AnalyticsStatisticsScreenState();
}

class _AnalyticsStatisticsScreenState
    extends State<AnalyticsStatisticsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsProvider>().loadAnalytics();
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<AnalyticsProvider>().loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('City Analytics'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh analytics',
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.overview == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null && provider.overview == null) {
            return _buildError(provider.error!);
          }

          final overview = provider.overview;

          if (overview == null) {
            return _buildError('Analytics data is not available.');
          }

          final issueAnalytics = provider.issueAnalytics;
          final departments =
              provider.departmentAnalytics?.departments ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 22),

                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 700 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: [
                      StatisticsCard(
                        title: 'Total Issues',
                        value: overview.totalIssues,
                        icon: Icons.assignment_outlined,
                        color: AppColors.primary,
                      ),
                      StatisticsCard(
                        title: 'Pending',
                        value: overview.pendingIssues,
                        icon: Icons.pending_actions,
                        color: AppColors.warning,
                      ),
                      StatisticsCard(
                        title: 'In Progress',
                        value: overview.inProgressIssues,
                        icon: Icons.sync,
                        color: AppColors.cyan,
                      ),
                      StatisticsCard(
                        title: 'Resolved',
                        value: overview.resolvedIssues,
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      StatisticsCard(
                        title: 'High Priority',
                        value: overview.highPriorityIssues,
                        icon: Icons.priority_high,
                        color: AppColors.error,
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  _buildSectionTitle(
                    'Category Analytics',
                    'Issues reported by category',
                  ),
                  const SizedBox(height: 10),

                  if (issueAnalytics == null ||
                      issueAnalytics.categories.isEmpty)
                    _buildEmptyCard('No category data available.')
                  else
                    AnalyticsChart(
                      title: 'Issues by Category',
                      labels: issueAnalytics.categories
                          .map((item) => item.category)
                          .toList(),
                      values: issueAnalytics.categories
                          .map((item) => item.issueCount)
                          .toList(),
                      color: AppColors.primary,
                    ),

                  const SizedBox(height: 22),

                  _buildSectionTitle(
                    'Status Analytics',
                    'Current issue status distribution',
                  ),
                  const SizedBox(height: 10),

                  if (issueAnalytics == null ||
                      issueAnalytics.statuses.isEmpty)
                    _buildEmptyCard('No status data available.')
                  else
                    AnalyticsChart(
                      title: 'Issues by Status',
                      labels: issueAnalytics.statuses
                          .map((item) => item.status)
                          .toList(),
                      values: issueAnalytics.statuses
                          .map((item) => item.issueCount)
                          .toList(),
                      color: AppColors.cyan,
                    ),

                  const SizedBox(height: 22),

                  _buildSectionTitle(
                    'Monthly Trends',
                    'Issue reporting activity over time',
                  ),
                  const SizedBox(height: 10),

                  if (issueAnalytics == null ||
                      issueAnalytics.monthly.isEmpty)
                    _buildEmptyCard('No monthly trend data available.')
                  else
                    AnalyticsChart(
                      title: 'Monthly Reported Issues',
                      labels: issueAnalytics.monthly
                          .map((item) => item.month)
                          .toList(),
                      values: issueAnalytics.monthly
                          .map((item) => item.issueCount)
                          .toList(),
                      color: AppColors.success,
                    ),

                  const SizedBox(height: 22),

                  _buildSectionTitle(
                    'Department Performance',
                    'Issue statistics by department',
                  ),
                  const SizedBox(height: 10),

                  if (departments.isEmpty)
                    _buildEmptyCard('No department statistics available.')
                  else
                    ...departments.map(
                      (department) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                department.departmentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _departmentValue(
                                    'Total',
                                    department.totalIssues,
                                  ),
                                  _departmentValue(
                                    'Pending',
                                    department.pendingIssues,
                                  ),
                                  _departmentValue(
                                    'Resolved',
                                    department.resolvedIssues,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (provider.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Some analytics could not be refreshed: ${provider.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.white,
            size: 36,
          ),
          SizedBox(height: 14),
          Text(
            'Smart City Insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Monitor city issues, reporting trends and department performance.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: SizedBox(
        width: double.infinity,
        height: 110,
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      ),
    );
  }

  Widget _departmentValue(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
