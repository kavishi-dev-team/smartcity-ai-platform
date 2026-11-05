import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_model.dart';
import '../../ai/screens/ai_assistant_chat_screen.dart';
import '../../auth/providers/auth_provider.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() =>
      _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadCitizenDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-page background image
          Image.asset(
            'assets/images/smart_city.jpg',
            fit: BoxFit.cover,
          ),

          

          SafeArea(
            child: Consumer<DashboardProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading &&
                    provider.citizenDashboard == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (provider.error != null &&
                    provider.citizenDashboard == null) {
                  return _errorView(provider);
                }

                final dashboard = provider.citizenDashboard;

                if (dashboard == null) {
                  return const Center(
                    child: Text('No dashboard data available'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.loadCitizenDashboard,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildHeader(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 24, 20, 10),
                          child: _buildWelcome(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildStatistics(dashboard),
                      ),
                      SliverToBoxAdapter(
                        child: _buildQuickActions(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildRecentReports(
                          dashboard.recentReports,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 25),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_city,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMART CITY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Citizen Portal',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                ),
              ),

const SizedBox(width: 8),
IconButton(
  onPressed: () {
    context.read<AuthProvider>().logout();
  },
  icon: const Icon(
    Icons.logout,
    color: Colors.white,
    size: 24,
  ),
  tooltip: 'Logout',
),
            ],
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Building a Better City',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your voice matters. Help us make our city smarter, safer and cleaner.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 65,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome Back! 👋',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Here is an overview of your city reports.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(dynamic dashboard) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Reports Overview',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total Reports',
                  dashboard.totalReports,
                  Icons.assignment_outlined,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _statCard(
                  'Active Reports',
                  dashboard.activeReports,
                  Icons.pending_actions_rounded,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Resolved Reports',
                  dashboard.resolvedReports,
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _statCard(
                  'Community',
                  'Connected',
                  Icons.people_outline,
                  AppColors.cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(height: 15),
          Text(
            value.toString(),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _actionCard(
                'Report an Issue',
                'Report city problems',
                Icons.add_location_alt_outlined,
                AppColors.primary,
                () {},
              ),
              _actionCard(
                'My Reports',
                'View your submissions',
                Icons.assignment_outlined,
                AppColors.cyan,
                () {},
              ),
              _actionCard(
                'Track Reports',
                'Check report status',
                Icons.track_changes_rounded,
                AppColors.warning,
                () {},
              ),
              _actionCard(
                'AI Assistant',
                'Get smart assistance',
                Icons.smart_toy_outlined,
                AppColors.success,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AIAssistantChatScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }


Widget _actionCard(
  String title,
  String subtitle,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {

final imagePaths = {
  'Report an Issue': 'assets/images/actions/report.jpeg',
  'My Reports': 'assets/images/actions/my_reports.jpeg',
  'Track Reports': 'assets/images/actions/track_reports.jpeg',
  'AI Assistant': 'assets/images/actions/ai_assistant.jpeg',
};

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePaths[title]!,
              fit: BoxFit.contain,
            ),

            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 25,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildRecentReports(List<DashboardIssue> reports) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (reports.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 42,
                    color: AppColors.skyBlue,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Reports Yet',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your submitted city reports will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...reports.map(_issueCard),
        ],
      ),
    );
  }

  Widget _issueCard(DashboardIssue issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        leading: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.report_problem_outlined,
            color: AppColors.warning,
          ),
        ),
        title: Text(
          issue.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        subtitle: Text(
          '${issue.category} • ${issue.status} • ${issue.priority}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _errorView(DashboardProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 55,
              color: AppColors.error,
            ),
            const SizedBox(height: 15),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: provider.loadCitizenDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AIAssistantChatScreen(),
            ),
          );

          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      backgroundColor: Colors.white,
      indicatorColor: AppColors.lightBlue,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.smart_toy_outlined),
          label: 'AI Assistant',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
