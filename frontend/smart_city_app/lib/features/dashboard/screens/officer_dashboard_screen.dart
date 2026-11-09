import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../ai/screens/ai_analysis_results_screen.dart';
import '../../ai/screens/ai_assistant_chat_screen.dart';
import '../../ai/screens/ai_prioritized_issues_screen.dart';
import '../../ai/screens/complaint_clusters_screen.dart';
import '../../analytics/screens/analytics_statistics_screen.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/staff_management_screen.dart';
import '../../energy_water/screens/energy_problems_screen.dart';
import '../../energy_water/screens/energy_water_statistics_screen.dart';
import '../../energy_water/screens/water_leakage_reports_screen.dart';
import '../../energy_water/screens/water_problems_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../profile/screens/profile_screen.dart';
import '../../reporting/screens/my_reports_screen.dart';
import '../../reporting/screens/report_details_screen.dart';
import '../../safety/screens/air_quality_screen.dart';
import '../../safety/screens/complaint_history_screen.dart';
import '../../safety/screens/safety_alerts_screen.dart';
import '../../safety/screens/safety_problems_screen.dart';
import '../../traffic/screens/department_information_screen.dart';
import '../../traffic/screens/traffic_incident_map_screen.dart';
import '../../traffic/screens/traffic_problems_screen.dart';
import '../../traffic/screens/traffic_status_management_screen.dart';
import '../../waste/screens/collection_information_screen.dart';
import '../../waste/screens/waste_problems_screen.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/priority_issue_provider.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    await Future.wait([
      context.read<DashboardProvider>().loadOfficerDashboard(),
      context.read<PriorityIssueProvider>().loadIssues(),
      _loadUnreadCount(),
    ]);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (_) {}
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) _loadUnreadCount();
  }

  String _portalSubtitle(UserRole? role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin Control Center';
      case UserRole.cityManager:
        return 'City Manager Executive Portal';
      case UserRole.departmentOfficer:
        return 'Department Officer Operations Portal';
      default:
        return 'Officer Management Portal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final canViewStaffDirectory =
        role == UserRole.superAdmin || role == UserRole.cityManager;

    final tabs = <Widget>[
      _buildOverviewTab(),
      _buildOperationsTab(),
      const AnalyticsStatisticsScreen(),
      if (canViewStaffDirectory) const StaffManagementScreen(embedded: true),
      const ProfileScreen(embedded: true),
    ];

    final safeIndex = _selectedIndex >= tabs.length ? 0 : _selectedIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: safeIndex,
        children: tabs,
      ),
      floatingActionButton: safeIndex == 0 || safeIndex == 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => _open(const AIAssistantChatScreen()),
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('AI Assistant'),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigation(
        canViewStaffDirectory: canViewStaffDirectory,
        isSuperAdmin: role == UserRole.superAdmin,
        safeIndex: safeIndex,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SafeArea(
      child: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.officerDashboard == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.error != null && provider.officerDashboard == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.text),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshAll,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
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
                style: TextStyle(color: AppColors.text),
              ),
            );
          }

          final stats = dashboard.statistics;

          return RefreshIndicator(
            onRefresh: _refreshAll,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'City Operations Overview',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Real-time metrics across all city departments and reported issues.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 10.0;
                                final maxW = constraints.maxWidth;
                                final cols = maxW > 680 ? 5 : 2;
                                final cardW =
                                    (maxW - spacing * (cols - 1)) / cols;
                                final statItems = [
                                  _statCard(
                                    'Total Issues',
                                    stats.total,
                                    AppColors.primary,
                                    Icons.assignment_rounded,
                                    onTap: () => _open(
                                      const MyReportsScreen(
                                        showAllCityReports: true,
                                      ),
                                    ),
                                  ),
                                  _statCard(
                                    'Pending',
                                    stats.pending,
                                    AppColors.warning,
                                    Icons.pending_actions_rounded,
                                    onTap: () => _open(
                                      const MyReportsScreen(
                                        showAllCityReports: true,
                                      ),
                                    ),
                                  ),
                                  _statCard(
                                    'High Priority',
                                    stats.highPriority,
                                    AppColors.error,
                                    Icons.priority_high_rounded,
                                  ),
                                  _statCard(
                                    'In Progress',
                                    stats.inProgress,
                                    AppColors.cyan,
                                    Icons.sync_rounded,
                                  ),
                                  _statCard(
                                    'Resolved',
                                    stats.resolved,
                                    AppColors.success,
                                    Icons.check_circle_rounded,
                                  ),
                                ];

                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    for (var i = 0; i < statItems.length; i++)
                                      SizedBox(
                                        width: (cols == 2 &&
                                                i == statItems.length - 1)
                                            ? maxW
                                            : cardW,
                                        child: statItems[i],
                                      ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 18),
                            _buildRoleControlBanner(),
                            const SizedBox(height: 22),

                            // Quick Domain Management Cards
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Department & Domain Management',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _selectedIndex = 1),
                                  icon: const Icon(
                                    Icons.apps_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('All Modules'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildQuickDomainGrid(),

                            const SizedBox(height: 24),

                            // Analytics Banner Card
                            Card(
                              margin: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => setState(() => _selectedIndex = 2),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.brandGradient,
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.analytics_rounded,
                                        color: Colors.white,
                                        size: 34,
                                      ),
                                      SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'City Analytics & SLA Performance',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Inspect department efficiency, category breakdowns & trends',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 26),

                            // AI Priority Issues Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'AI Prioritized Issues Queue',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _open(const ComplaintClustersScreen()),
                                  icon: const Icon(
                                    Icons.hub_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Clusters'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _open(const AIPrioritizedIssuesScreen()),
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Full Queue'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Filter and review AI-triaged citizen reports across city departments.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildPriorityFilters(),
                            _buildPriorityIssuesList(),

                            const SizedBox(height: 26),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent City Issues',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _open(
                                    const MyReportsScreen(
                                      showAllCityReports: true,
                                    ),
                                  ),
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (dashboard.recentIssues.isEmpty)
                              Card(
                                margin: EdgeInsets.zero,
                                child: const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'No recent issues available.',
                                      style: TextStyle(color: AppColors.muted),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...dashboard.recentIssues.map(_issueCard),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
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

  Widget _buildHeader() {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        border: Border(
          bottom: BorderSide(
            color: AppColors.skyBlue.withValues(alpha: 0.45),
            width: 2,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SMART CITY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          _portalSubtitle(user?.role),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => _open(const NotificationsScreen()),
                    icon: Badge(
                      isLabelVisible: _unreadCount > 0,
                      label: Text('$_unreadCount'),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      final r = context.read<AuthProvider>().user?.role;
                      final hasStaffTab = r == UserRole.superAdmin ||
                          r == UserRole.cityManager;
                      setState(() => _selectedIndex = hasStaffTab ? 4 : 3);
                    },
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Logout',
                    onPressed: () => context.read<AuthProvider>().logout(),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user?.fullName ?? "Officer"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'staff@smartcity-dev.com',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role.displayName.toUpperCase() ?? 'STAFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleControlBanner() {
    final user = context.watch<AuthProvider>().user;
    final role = user?.role ?? UserRole.departmentOfficer;

    if (role == UserRole.superAdmin) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.security_rounded,
                  color: AppColors.skyBlue,
                  size: 32,
                ),
                SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Super Admin Full Access & Staff Provisioning',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Register Department Officers & City Managers, assign departments, and manage role permissions.',
                        style: TextStyle(
                          color: AppColors.lightBlue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
              ),
              onPressed: () => _open(const StaffManagementScreen()),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text(
                'Manage Officers & Roles',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    if (role == UserRole.cityManager) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'City Manager Executive Access',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cross-department SLA oversight, issue routing, safety alerts, and municipal staff directory.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _open(const StaffManagementScreen()),
              icon: const Icon(Icons.groups_rounded, size: 17),
              label: const Text('Staff Directory'),
            ),
          ],
        ),
      );
    }

    // Department Officer operational scope card
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.engineering_rounded,
              color: AppColors.cyan,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department Officer Operations${user?.departmentName != null ? " • ${user!.departmentName}" : ""}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user?.position ?? "Field & Case Officer"} — Inspect assigned cases, update field statuses (Assigned → In Progress → Resolved), and post citizen updates.',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDomainGrid() {
    final items = [
      (
        'Waste Management',
        'Reports & schedules',
        Icons.delete_sweep_rounded,
        AppColors.waste,
        () => _open(const WasteProblemsScreen()),
      ),
      (
        'Energy & Water',
        'Outages, leaks & maps',
        Icons.bolt_rounded,
        AppColors.energy,
        () => _open(const EnergyWaterDashboardMenu()),
      ),
      (
        'Traffic Management',
        'Signals, map & officers',
        Icons.traffic_rounded,
        AppColors.traffic,
        () => _open(const TrafficProblemsScreen()),
      ),
      (
        'Safety & Complaints',
        'Officer case management',
        Icons.shield_outlined,
        AppColors.safety,
        () => _open(const ComplaintHistoryScreen(isOfficer: true)),
      ),
      (
        'Air Quality',
        'Station AQI & history',
        Icons.air_rounded,
        AppColors.cyan,
        () => _open(const AirQualityScreen()),
      ),
      (
        'Departments',
        'Directory & assignments',
        Icons.apartment_rounded,
        AppColors.primaryDark,
        () => _open(const DepartmentInformationScreen()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final maxW = constraints.maxWidth;
        final cols = maxW > 680
            ? 3
            : maxW < 320
                ? 1
                : 2;
        final itemWidth = (maxW - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final (title, sub, icon, color, onTap) in items)
              SizedBox(
                width: itemWidth,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterDropdownPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.lightBlue
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryDark : AppColors.text,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isSelected ? AppColors.primaryDark : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityPicker(
    BuildContext context,
    PriorityIssueProvider provider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by AI Priority',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              for (final p in [null, 'high', 'medium', 'low'])
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: provider.selectedPriority == p,
                  selectedTileColor: AppColors.lightBlue,
                  leading: Icon(
                    Icons.flag_rounded,
                    color: p == 'high'
                        ? AppColors.error
                        : p == 'medium'
                            ? AppColors.warning
                            : p == 'low'
                                ? AppColors.success
                                : AppColors.primary,
                    size: 20,
                  ),
                  title: Text(
                    p == null ? 'All Priorities' : p.toUpperCase(),
                    style: TextStyle(
                      fontWeight: provider.selectedPriority == p
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: provider.selectedPriority == p
                          ? AppColors.primaryDark
                          : AppColors.text,
                    ),
                  ),
                  trailing: provider.selectedPriority == p
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.applyFilters(
                      priority: p,
                      category: provider.selectedCategory,
                      status: provider.selectedStatus,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfficerStatusPicker(
    BuildContext context,
    PriorityIssueProvider provider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Issue Status',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              for (final s in [null, 'reported', 'in_progress', 'resolved'])
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: provider.selectedStatus == s,
                  selectedTileColor: AppColors.lightBlue,
                  leading: Icon(
                    Icons.circle,
                    size: 12,
                    color: s == 'reported'
                        ? AppColors.primary
                        : s == 'in_progress'
                            ? AppColors.warning
                            : s == 'resolved'
                                ? AppColors.success
                                : AppColors.navy,
                  ),
                  title: Text(
                    s == null
                        ? 'All Statuses'
                        : s.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontWeight: provider.selectedStatus == s
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: provider.selectedStatus == s
                          ? AppColors.primaryDark
                          : AppColors.text,
                    ),
                  ),
                  trailing: provider.selectedStatus == s
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.applyFilters(
                      priority: provider.selectedPriority,
                      category: provider.selectedCategory,
                      status: s,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfficerCategoryPicker(
    BuildContext context,
    PriorityIssueProvider provider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Category',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              for (final c in [
                null,
                'traffic',
                'waste',
                'water',
                'energy',
                'safety',
                'complaint',
              ])
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: provider.selectedCategory == c,
                  selectedTileColor: AppColors.lightBlue,
                  leading: Icon(
                    switch (c) {
                      'traffic' => Icons.traffic_rounded,
                      'waste' => Icons.delete_outline_rounded,
                      'water' => Icons.water_drop_outlined,
                      'energy' => Icons.bolt_rounded,
                      'safety' => Icons.shield_outlined,
                      'complaint' => Icons.record_voice_over_outlined,
                      _ => Icons.apps_rounded,
                    },
                    color: AppColors.primary,
                    size: 20,
                  ),
                  title: Text(
                    c == null ? 'All Categories' : c.toUpperCase(),
                    style: TextStyle(
                      fontWeight: provider.selectedCategory == c
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: provider.selectedCategory == c
                          ? AppColors.primaryDark
                          : AppColors.text,
                    ),
                  ),
                  trailing: provider.selectedCategory == c
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.applyFilters(
                      priority: provider.selectedPriority,
                      category: c,
                      status: provider.selectedStatus,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityFilters() {
    return Consumer<PriorityIssueProvider>(
      builder: (context, filterProvider, child) {
        final hasFilters = filterProvider.selectedPriority != null ||
            filterProvider.selectedStatus != null ||
            filterProvider.selectedCategory != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterDropdownPill(
                  icon: Icons.flag_rounded,
                  iconColor: filterProvider.selectedPriority == 'high'
                      ? AppColors.error
                      : filterProvider.selectedPriority == 'medium'
                          ? AppColors.warning
                          : AppColors.primary,
                  label: filterProvider.selectedPriority != null
                      ? 'Priority: ${filterProvider.selectedPriority!.toUpperCase()}'
                      : 'Priority: All',
                  isSelected: filterProvider.selectedPriority != null,
                  onTap: () => _showPriorityPicker(context, filterProvider),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdownPill(
                  icon: Icons.tune_rounded,
                  iconColor: AppColors.primary,
                  label: filterProvider.selectedStatus != null
                      ? 'Status: ${filterProvider.selectedStatus!.replaceAll('_', ' ').toUpperCase()}'
                      : 'Status: All',
                  isSelected: filterProvider.selectedStatus != null,
                  onTap: () =>
                      _showOfficerStatusPicker(context, filterProvider),
                ),
                const SizedBox(width: 8),
                _buildFilterDropdownPill(
                  icon: Icons.category_outlined,
                  iconColor: AppColors.primary,
                  label: filterProvider.selectedCategory != null
                      ? 'Category: ${filterProvider.selectedCategory!.toUpperCase()}'
                      : 'Category: All',
                  isSelected: filterProvider.selectedCategory != null,
                  onTap: () =>
                      _showOfficerCategoryPicker(context, filterProvider),
                ),
                if (hasFilters) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: filterProvider.clearFilters,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded,
                              size: 14, color: AppColors.error),
                          SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityIssuesList() {
    return Consumer<PriorityIssueProvider>(
      builder: (context, priorityProvider, child) {
        if (priorityProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (priorityProvider.error != null) {
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                priorityProvider.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        if (priorityProvider.issues.isEmpty) {
          return Card(
            margin: EdgeInsets.zero,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No AI-prioritized issues match the selected filters.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
          );
        }

        return Column(
          children: priorityProvider.issues.take(6).map((issue) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  if (issue.category.toLowerCase() == 'traffic') {
                    _open(
                      TrafficStatusManagementScreen(
                        issueId: issue.issueId,
                        categoryLabel: 'Traffic',
                      ),
                    );
                  } else {
                    _open(ReportDetailsScreen(issueId: issue.issueId));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.error,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 5,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '${issue.category.toUpperCase()} • ${issue.status.replaceAll('_', ' ').toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'AI: ${issue.aiPriority.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Final: ${issue.finalPriority.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.lightBlue,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: () async {
                          await _open(
                            TrafficStatusManagementScreen(
                              issueId: issue.issueId,
                              categoryLabel: issue.category.toUpperCase(),
                            ),
                          );
                          if (mounted) _refreshAll();
                        },
                        icon: const Icon(Icons.manage_accounts_rounded, size: 15),
                        label: const Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOperationsTab() {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('${user?.role.displayName ?? "Officer"} Operations Hub'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _open(const NotificationsScreen()),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'City Service & Officer Modules',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Access domain dashboards, assign departments, update statuses, and review citizen reports.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (user?.role == UserRole.superAdmin ||
                    user?.role == UserRole.cityManager)
                  _opsCard(
                    title: user?.role == UserRole.superAdmin
                        ? 'Staff Provisioning & Access Control (Super Admin)'
                        : 'Municipal Staff & Department Directory',
                    subtitle: user?.role == UserRole.superAdmin
                        ? 'Register Department Officers, City Managers & Super Admins, assign departments, and control role permissions.'
                        : 'View active Department Officers, City Managers, and municipal department assignments.',
                    icon: Icons.admin_panel_settings_rounded,
                    color: AppColors.navy,
                    onMainTap: () => _open(const StaffManagementScreen()),
                    chips: [
                      (
                        user?.role == UserRole.superAdmin
                            ? 'Register & Manage Staff'
                            : 'View Staff Directory',
                        () => _open(const StaffManagementScreen()),
                      ),
                      (
                        'Departments Directory',
                        () => _open(const DepartmentInformationScreen()),
                      ),
                    ],
                  ),
                _opsCard(
                  title: 'Traffic & Road Management',
                  subtitle:
                      'Inspect traffic incidents, road map markers, department directory, and officer status management.',
                  icon: Icons.traffic_rounded,
                  color: AppColors.primary,
                  onMainTap: () => _open(const TrafficProblemsScreen()),
                  chips: [
                    ('Traffic Reports', () => _open(const TrafficProblemsScreen())),
                    ('Incident Map', () => _open(const TrafficIncidentMapScreen())),
                    ('Departments', () => _open(const DepartmentInformationScreen())),
                  ],
                ),
                _opsCard(
                  title: 'Safety, Alerts & Officer Complaints',
                  subtitle:
                      'Assign complaints to departments & officers, post public timeline updates, and manage safety alerts.',
                  icon: Icons.shield_outlined,
                  color: AppColors.error,
                  onMainTap: () =>
                      _open(const ComplaintHistoryScreen(isOfficer: true)),
                  chips: [
                    (
                      'Officer Complaints Console',
                      () => _open(const ComplaintHistoryScreen(isOfficer: true)),
                    ),
                    ('Safety Problems', () => _open(const SafetyProblemsScreen())),
                    ('Safety Alerts', () => _open(const SafetyAlertsScreen())),
                  ],
                ),
                _opsCard(
                  title: 'Waste & Collection Management',
                  subtitle:
                      'Monitor municipal waste overflow reports, collection schedules, and recycling programs.',
                  icon: Icons.delete_sweep_rounded,
                  color: AppColors.cyan,
                  onMainTap: () => _open(const WasteProblemsScreen()),
                  chips: [
                    ('Waste Issues', () => _open(const WasteProblemsScreen())),
                    (
                      'Collection Schedules',
                      () => _open(const CollectionInformationScreen()),
                    ),
                  ],
                ),
                _opsCard(
                  title: 'Energy & Water Utilities',
                  subtitle:
                      'Track power outages, street lighting faults, water pipe leakages, and utility statistics.',
                  icon: Icons.bolt_rounded,
                  color: AppColors.warning,
                  onMainTap: () => _open(const EnergyWaterDashboardMenu()),
                  chips: [
                    ('Energy Issues', () => _open(const EnergyProblemsScreen())),
                    ('Water Issues', () => _open(const WaterProblemsScreen())),
                    (
                      'Leakage Reports',
                      () => _open(const WaterLeakageReportsScreen()),
                    ),
                    (
                      'Utility Stats',
                      () => _open(const EnergyWaterStatisticsScreen()),
                    ),
                  ],
                ),
                _opsCard(
                  title: 'Air Quality & Environmental Monitoring',
                  subtitle:
                      'Review AQI readings across Colombo, Kandy, Galle & Jaffna stations.',
                  icon: Icons.air_rounded,
                  color: AppColors.success,
                  onMainTap: () => _open(const AirQualityScreen()),
                  chips: [
                    ('Live AQI Stations', () => _open(const AirQualityScreen())),
                    (
                      'All City Reports',
                      () => _open(
                        const MyReportsScreen(showAllCityReports: true),
                      ),
                    ),
                  ],
                ),
                _opsCard(
                  title: 'AI Triage, Clusters & Analysis',
                  subtitle:
                      'Review AI-prioritized reports, inspect complaint clusters, and run live AI issue analysis.',
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.primaryDark,
                  onMainTap: () => _open(const AIPrioritizedIssuesScreen()),
                  chips: [
                    (
                      'Prioritized Queue',
                      () => _open(const AIPrioritizedIssuesScreen()),
                    ),
                    (
                      'Issue Clusters',
                      () => _open(const ComplaintClustersScreen()),
                    ),
                    (
                      'AI Analysis Inspector',
                      () => _open(const AIAnalysisResultsScreen()),
                    ),
                    (
                      'AI Chat Assistant',
                      () => _open(const AIAssistantChatScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _opsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onMainTap,
    required List<(String, VoidCallback)> chips,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onMainTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, action) in chips)
                    ActionChip(
                      label: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      backgroundColor: AppColors.background,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: action,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    int value,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: color.withValues(alpha: 0.7),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _issueCard(DashboardIssue issue) {
    final categoryLower = issue.category.toLowerCase();
    final (IconData catIcon, Color catColor) = switch (categoryLower) {
      'traffic' => (Icons.traffic_rounded, AppColors.primary),
      'waste' => (Icons.delete_sweep_rounded, AppColors.cyan),
      'energy' => (Icons.bolt_rounded, AppColors.warning),
      'water' => (Icons.water_drop_rounded, AppColors.primary),
      'safety' || 'complaint' => (Icons.shield_outlined, AppColors.error),
      'air_quality' => (Icons.air_rounded, AppColors.success),
      _ => (Icons.report_problem_rounded, AppColors.warning),
    };

    final statusLower = issue.status.toLowerCase();
    final Color statusColor = switch (statusLower) {
      'resolved' || 'closed' => AppColors.success,
      'in_progress' => AppColors.primary,
      'assigned' => AppColors.cyan,
      _ => AppColors.warning,
    };

    final priorityLower = issue.priority.toLowerCase();
    final Color priorityColor = switch (priorityLower) {
      'critical' || 'high' => AppColors.error,
      'medium' => AppColors.warning,
      _ => AppColors.primary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(ReportDetailsScreen(issueId: issue.id)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(catIcon, color: catColor, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            issue.category.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: catColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            issue.status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${issue.priority.toUpperCase()} PRIORITY',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lightBlue,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: () async {
                  await _open(
                    TrafficStatusManagementScreen(
                      issueId: issue.id,
                      categoryLabel: issue.category.toUpperCase(),
                    ),
                  );
                  if (mounted) _refreshAll();
                },
                icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                label: const Text(
                  'Manage',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation({
    required bool canViewStaffDirectory,
    required bool isSuperAdmin,
    required int safeIndex,
  }) {
    return NavigationBar(
      selectedIndex: safeIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.lightBlue,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
          label: 'Dashboard',
        ),
        const NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps, color: AppColors.primary),
          label: 'Operations',
        ),
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics, color: AppColors.primary),
          label: 'Analytics',
        ),
        if (canViewStaffDirectory)
          NavigationDestination(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primary,
            ),
            label: isSuperAdmin ? 'Staff & Roles' : 'Staff',
          ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'Profile',
        ),
      ],
    );
  }
}
