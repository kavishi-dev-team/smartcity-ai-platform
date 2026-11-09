import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../ai/screens/ai_assistant_chat_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../profile/screens/profile_screen.dart';
import '../../reporting/screens/my_reports_screen.dart';
import '../../reporting/screens/report_details_screen.dart';
import '../../reporting/screens/report_problem_screen.dart';
import '../../reporting/widgets/issue_location_tracker_card.dart';
import '../../reporting/widgets/quick_issue_report_sheet.dart';
import '../../safety/models/air_quality_model.dart';
import '../../safety/models/safety_issue_model.dart';
import '../../safety/screens/air_quality_screen.dart';
import '../../safety/screens/complaint_history_screen.dart';
import '../../safety/screens/safety_alerts_screen.dart';
import '../../safety/screens/safety_problems_screen.dart';
import '../../safety/services/safety_service.dart';
import '../../traffic/screens/traffic_problems_screen.dart';
import '../../waste/screens/waste_problems_screen.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() =>
      _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  int _selectedIndex = 0;
  String _myReportsStatusFilter = 'all';
  int _myReportsRefreshToken = 0;
  int? _lastLoadedUserId;

  final SafetyService _safetyService = SafetyService();
  final NotificationService _notificationService = NotificationService();

  AirQualityReading? _liveAqi;
  SafetySummary? _safetySummary;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboard();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    if (currentUserId != null && currentUserId != _lastLoadedUserId) {
      _lastLoadedUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshDashboard();
      });
    }
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().user?.id;
    await Future.wait([
      context.read<DashboardProvider>().loadCitizenDashboard(userId: userId),
      _loadLiveCityPulse(),
    ]);
    if (mounted) {
      setState(() {
        _myReportsRefreshToken++;
      });
    }
  }

  void _openMyReportsTab({String statusFilter = 'all'}) {
    setState(() {
      _myReportsStatusFilter = statusFilter;
      _myReportsRefreshToken++;
      _selectedIndex = 2;
    });
    _refreshDashboard();
  }

  Future<void> _loadLiveCityPulse() async {
    try {
      final user = context.read<AuthProvider>().user;
      final reportedBy = (user != null && user.isCitizen) ? user.id : null;
      final aqiFuture = _safetyService.fetchLatestAirQuality();
      final safetyFuture =
          _safetyService.fetchSafetySummary(reportedBy: reportedBy);
      final unreadFuture = _notificationService.getUnreadCount();

      final results = await Future.wait<Object?>([
        aqiFuture.then<Object?>((v) => v).catchError((_) => null),
        safetyFuture.then<Object?>((v) => v).catchError((_) => null),
        unreadFuture.then<Object?>((v) => v).catchError((_) => 0),
      ]);

      if (!mounted) return;
      final aqiList = results[0] as List<AirQualityReading>?;
      final summary = results[1] as SafetySummary?;
      final unread = results[2] as int? ?? 0;

      setState(() {
        if (aqiList != null && aqiList.isNotEmpty) {
          _liveAqi = aqiList.first;
        }
        _safetySummary = summary;
        _unreadNotifications = unread;
      });
    } catch (_) {}
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (mounted) {
      _refreshDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Restored Full-Page Smart City Background Image
        Image.asset(
          'assets/images/smart_city.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: AppColors.background),
        ),
        // Subtle legibility tint over the background photo
        Container(
          color: AppColors.primaryDark.withValues(alpha: 0.18),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(),
              const ReportProblemScreen(embedded: true),
              MyReportsScreen(
                embedded: true,
                initialStatus: _myReportsStatusFilter,
                refreshToken: _myReportsRefreshToken,
                onBackToDashboard: () => setState(() => _selectedIndex = 0),
              ),
              const ProfileScreen(embedded: true),
            ],
          ),
          floatingActionButton: _selectedIndex == 0
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  onPressed: () => _open(const AIAssistantChatScreen()),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('AI Assistant'),
                )
              : null,
          bottomNavigationBar: _buildBottomNavigation(),
        ),
      ],
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.citizenDashboard == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (provider.error != null && provider.citizenDashboard == null) {
            return _errorView(provider);
          }

          final dashboard = provider.citizenDashboard;

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLiveCityPulseBanner(),
                          if (dashboard != null) _buildStatistics(dashboard),
                          _buildQuickActions(),
                          _buildServiceDomainStrip(),
                          if (dashboard != null)
                            _buildRecentReports(dashboard.recentReports),
                          const SizedBox(height: 85),
                        ],
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
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.fullName.isNotEmpty == true)
        ? user!.fullName.split(' ').first
        : 'Citizen';
    final addressText = (user?.address != null && user!.address!.trim().isNotEmpty)
        ? user.address!.trim()
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy.withValues(alpha: 0.94),
            AppColors.primary.withValues(alpha: 0.90),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.skyBlue.withValues(alpha: 0.45),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
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
                      Icons.location_city_rounded,
                      color: Colors.white,
                      size: 26,
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
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Citizen Intelligence Portal',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => _open(const NotificationsScreen()),
                    icon: Badge(
                      isLabelVisible: _unreadNotifications > 0,
                      label: Text('$_unreadNotifications'),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => setState(() => _selectedIndex = 3),
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
                    onPressed: () => context.read<AuthProvider>().logout(),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 13,
                          color: AppColors.skyBlue,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'CITIZEN PORTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (addressText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.skyBlue,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              addressText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome back, $firstName! 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Monitor live city conditions, report infrastructure issues, and track municipal resolutions in real time.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 460;
                    const textColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need to report a city problem?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Submit GPS-pinned reports for Waste, Energy & Water, Traffic, Safety & Air Quality.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    );

                    final actionRow = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                          ),
                          onPressed: () async {
                            await QuickIssueReportSheet.show(context);
                            if (mounted) _refreshDashboard();
                          },
                          icon: const Icon(
                            Icons.add_location_alt_rounded,
                            size: 18,
                          ),
                          label: const Text('Quick Report'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                          ),
                          onPressed: () => _open(const ReportProblemScreen()),
                          icon: const Icon(Icons.hub_outlined, size: 17),
                          label: const Text('Service Hub'),
                        ),
                      ],
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textColumn,
                          const SizedBox(height: 12),
                          actionRow,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        const Expanded(child: textColumn),
                        const SizedBox(width: 12),
                        actionRow,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveCityPulseBanner() {
    final aqiText = _liveAqi != null
        ? 'AQI ${_liveAqi!.aqi} (${_liveAqi!.area})'
        : 'AQI Live';
    final alertsCount = _safetySummary?.activeAlerts ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 440;

          final aqiWidget = InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _open(const AirQualityScreen()),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.air_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sri Lanka AQI',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        aqiText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final safetyWidget = InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _open(const SafetyAlertsScreen()),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Safety Alerts',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$alertsCount Active',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          final mapPill = InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _open(
              const DomainLocationTrackerScreen(category: 'all'),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'City Map',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          );

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isNarrow
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: aqiWidget),
                          Container(
                            width: 1,
                            height: 32,
                            color: AppColors.border,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          Expanded(child: safetyWidget),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: mapPill,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: aqiWidget),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(child: safetyWidget),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      mapPill,
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildStatistics(CitizenDashboard dashboard) {
    final liveAqiStat = _liveAqi != null ? '${_liveAqi!.aqi}' : 'Live';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total Reports',
                  dashboard.totalReports,
                  Icons.assignment_outlined,
                  AppColors.primary,
                  subtitle: 'All your submissions',
                  onTap: () => _openMyReportsTab(statusFilter: 'all'),
                ),
              ),
              Expanded(
                child: _statCard(
                  'Active Reports',
                  dashboard.activeReports,
                  Icons.pending_actions_rounded,
                  AppColors.warning,
                  subtitle: 'In progress or reported',
                  onTap: () => _openMyReportsTab(statusFilter: 'active'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Resolved',
                  dashboard.resolvedReports,
                  Icons.check_circle_outline,
                  AppColors.success,
                  subtitle: 'Completed cases',
                  onTap: () => _openMyReportsTab(statusFilter: 'resolved'),
                ),
              ),
              Expanded(
                child: _statCard(
                  'City AQI Index',
                  liveAqiStat,
                  Icons.air_rounded,
                  AppColors.cyan,
                  subtitle: _liveAqi?.area ?? 'Sri Lanka Live',
                  onTap: () => _open(const AirQualityScreen()),
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
    Color color, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white.withValues(alpha: 0.94),
      elevation: 3,
      margin: const EdgeInsets.all(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value.toString(),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 620
                  ? 4
                  : constraints.maxWidth < 310
                      ? 1
                      : 2;
              const spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
              final itemHeight = constraints.maxWidth < 380 ? 132.0 : 122.0;

              final actions = [
                (
                  'Report an Issue',
                  'Submit city problems',
                  Icons.add_location_alt_outlined,
                  AppColors.primary,
                  () => _open(const ReportProblemScreen()),
                ),
                (
                  'My Reports',
                  'View your submissions',
                  Icons.assignment_outlined,
                  AppColors.cyan,
                  () => _open(const MyReportsScreen()),
                ),
                (
                  'Track Reports',
                  'Check issue progress',
                  Icons.track_changes_rounded,
                  AppColors.warning,
                  () => _open(const ComplaintHistoryScreen()),
                ),
                (
                  'AI Assistant',
                  'Get smart assistance',
                  Icons.smart_toy_outlined,
                  AppColors.success,
                  () => _open(const AIAssistantChatScreen()),
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final (title, sub, icon, color, onTap) in actions)
                    SizedBox(
                      width: itemWidth,
                      height: itemHeight,
                      child: _actionCard(title, sub, icon, color, onTap),
                    ),
                ],
              );
            },
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    ColoredBox(color: AppColors.primaryDark),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      AppColors.navy.withValues(alpha: 0.84),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  Widget _buildServiceDomainStrip() {
    final domains = [
      (
        'Waste Management',
        'Schedules & overflow',
        Icons.delete_sweep_rounded,
        AppColors.waste,
        () => _open(const WasteProblemsScreen()),
      ),
      (
        'Energy & Water',
        'Outages & leak maps',
        Icons.bolt_rounded,
        AppColors.energy,
        () => _open(const EnergyWaterDashboardMenu()),
      ),
      (
        'Traffic Control',
        'Signals & live map',
        Icons.traffic_rounded,
        AppColors.traffic,
        () => _open(const TrafficProblemsScreen()),
      ),
      (
        'Public Safety',
        'Alerts & complaints',
        Icons.shield_outlined,
        AppColors.safety,
        () => _open(const SafetyProblemsScreen()),
      ),
      (
        'Air Quality (AQI)',
        'Live PM2.5 & station index',
        Icons.air_rounded,
        AppColors.cyan,
        () => _open(const AirQualityScreen()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'City Service Hubs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  foregroundColor: AppColors.primaryDark,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _open(const ReportProblemScreen()),
                icon: const Icon(Icons.grid_view_rounded, size: 16),
                label: const Text('Service Hub'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final maxW = constraints.maxWidth;
              final int cols = maxW >= 720
                  ? 5
                  : maxW >= 500
                      ? 3
                      : maxW < 310
                          ? 1
                          : 2;
              final standardWidth = (maxW - spacing * (cols - 1)) / cols;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (var i = 0; i < domains.length; i++)
                    Builder(
                      builder: (context) {
                        final (label, subtitle, icon, color, onTap) =
                            domains[i];
                        // When in 2-column layout with 5 items, let the 5th card span full width
                        final isLastOddInTwoCol =
                            cols == 2 && i == domains.length - 1;
                        final cardWidth =
                            isLastOddInTwoCol ? maxW : standardWidth;

                        return SizedBox(
                          width: cardWidth,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.navy
                                          .withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Icon(icon, color: color, size: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: color,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReports(List<DashboardIssue> reports) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Recent Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.90),
                  foregroundColor: AppColors.primaryDark,
                ),
                onPressed: () => _open(const MyReportsScreen()),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (reports.isEmpty)
            Card(
              color: Colors.white.withValues(alpha: 0.90),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 42,
                      color: AppColors.skyBlue,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Reports Yet',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your submitted city reports will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _open(const ReportProblemScreen()),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Report an Issue'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...reports.map(_issueCard),
        ],
      ),
    );
  }

  Widget _issueCard(DashboardIssue issue) {
    final categoryLower = issue.category.toLowerCase();
    final (IconData catIcon, Color catColor) = (
      AppColors.categoryIcon(categoryLower),
      AppColors.categoryColor(categoryLower),
    );

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
      color: Colors.white.withValues(alpha: 0.95),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.primaryDark,
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

  Widget _errorView(DashboardProvider provider) {
    return Center(
      child: Card(
        color: Colors.white.withValues(alpha: 0.92),
        margin: const EdgeInsets.all(24),
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
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _refreshDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
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
          if (index == 2) {
            _myReportsRefreshToken++;
          }
        });
        if (index == 0 || index == 2) {
          _refreshDashboard();
        }
      },
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      indicatorColor: AppColors.lightBlue,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.hub_outlined),
          selectedIcon: Icon(Icons.hub, color: AppColors.primary),
          label: 'Report Hub',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
          label: 'My Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'Profile',
        ),
      ],
    );
  }
}
