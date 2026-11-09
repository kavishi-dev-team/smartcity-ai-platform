import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/traffic/screens/traffic_problems_screen.dart';
import 'features/energy_water/screens/energy_problems_screen.dart';
import 'features/energy_water/screens/water_problems_screen.dart';
import 'features/energy_water/screens/water_leakage_reports_screen.dart';
import 'features/energy_water/screens/energy_water_statistics_screen.dart';
import 'features/energy_water/screens/energy_water_report_screen.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';

import 'features/ai/providers/ai_provider.dart';
import 'features/ai/screens/ai_assistant_chat_screen.dart';

import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/providers/priority_issue_provider.dart';
import 'features/dashboard/screens/officer_dashboard_screen.dart';

import 'features/analytics/providers/analytics_provider.dart';
import 'features/safety/services/safety_service.dart';
import 'features/waste/screens/waste_problems_screen.dart';


class SmartCityApp extends StatefulWidget {
  const SmartCityApp({super.key});

  @override
  State<SmartCityApp> createState() => _SmartCityAppState();
}

class _SmartCityAppState extends State<SmartCityApp> {
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  late final ApiClient _api = ApiClient();

  late final AuthProvider _auth =
      AuthProvider(AuthService(_api), _api);

  AuthStatus _lastStatus = AuthStatus.unknown;

  @override
  void initState() {
    super.initState();
    SafetyService.accessTokenProvider = _api.tokenStorage.readAccessToken;
    _auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final status = _auth.status;

    final wasAuthenticated =
        _lastStatus == AuthStatus.authenticated;

    _lastStatus = status;

    if (wasAuthenticated &&
        status == AuthStatus.unauthenticated) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: _auth,
        ),

        ChangeNotifierProvider(
          create: (_) => AIProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => PriorityIssueProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => AnalyticsProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Smart City AI Platform',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        navigatorKey: _navigatorKey,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
        routes: {
          '/officer': (context) =>
              const OfficerDashboardScreen(),
        },
      ),
    );
  }
}


final ThemeData appTheme = AppTheme.light;


class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart City AI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_city,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Smart City AI Platform',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Intelligent solutions for a better city.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'City Overview',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OverviewCard(
                    title: 'Traffic',
                    value: 'Monitoring',
                    icon: Icons.traffic,
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TrafficProblemsScreen(),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: OverviewCard(
                    title: 'Waste',
                    value: 'Management',
                    icon: Icons.delete_outline,
                    color: AppColors.cyan,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const WasteProblemsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const Row(
              children: [
                Expanded(
                  child: OverviewCard(
                    title: 'Energy',
                    value: 'Monitoring',
                    icon: Icons.bolt,
                    color: AppColors.warning,
                  ),
                ),

                Expanded(
                  child: OverviewCard(
                    title: 'Water',
                    value: 'Management',
                    icon: Icons.water_drop_outlined,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Energy & Water dashboard
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const EnergyWaterDashboardMenu(),
                    ),
                  );
                },
                icon: const Icon(Icons.dashboard),
                label: const Text('Explore Dashboard'),
              ),
            ),

            const SizedBox(height: 12),

            // AI assistant
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AIAssistantChatScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('AI Assistant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const OverviewCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnergyWaterDashboardMenu extends StatelessWidget {
  const EnergyWaterDashboardMenu({super.key});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Energy & Water Utilities Hub'),
        actions: [
          IconButton(
            tooltip: 'Submit Utility Report',
            onPressed: () => openScreen(
              context,
              const EnergyWaterReportScreen(),
            ),
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Energy & Water Infrastructure Hub',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Monitor power outages, street lighting faults, water pipe leakages, and live utility performance.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                            ),
                            onPressed: () => openScreen(
                              context,
                              const EnergyWaterReportScreen(),
                            ),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Report Utility Problem'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            onPressed: () => openScreen(
                              context,
                              const WaterLeakageReportsScreen(),
                            ),
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Live Leakage Map'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            onPressed: () => openScreen(
                              context,
                              const EnergyWaterStatisticsScreen(),
                            ),
                            icon: const Icon(Icons.bar_chart_rounded, size: 18),
                            label: const Text('Utility Analytics'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Utility Management Modules',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select a module below to inspect reported incidents, officer assignments, or analytics.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 14),

                DashboardMenuCard(
                  title: 'Energy Problems & Outages',
                  subtitle:
                      'Inspect power grid outages, street lighting faults, and transformer alerts with full officer case management.',
                  badge: 'POWER & LIGHTING',
                  icon: Icons.bolt_rounded,
                  color: AppColors.warning,
                  onTap: () => openScreen(
                    context,
                    const EnergyProblemsScreen(),
                  ),
                ),

                DashboardMenuCard(
                  title: 'Water Supply Problems',
                  subtitle:
                      'Track low pressure, supply interruptions, contamination reports, and municipal repair dispatches.',
                  badge: 'WATER SUPPLY',
                  icon: Icons.water_drop_rounded,
                  color: AppColors.primary,
                  onTap: () => openScreen(
                    context,
                    const WaterProblemsScreen(),
                  ),
                ),

                DashboardMenuCard(
                  title: 'Water Leakage Reports & Map',
                  subtitle:
                      'Interactive Sri Lanka map of active pipe bursts and roadside water leakages with severity pins.',
                  badge: 'LIVE GIS MAP',
                  icon: Icons.location_on_rounded,
                  color: AppColors.success,
                  onTap: () => openScreen(
                    context,
                    const WaterLeakageReportsScreen(),
                  ),
                ),

                DashboardMenuCard(
                  title: 'Energy & Water Statistics',
                  subtitle:
                      'Review category breakdowns, resolution rates, and SLA metrics across energy and water utilities.',
                  badge: 'ANALYTICS',
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.cyan,
                  onTap: () => openScreen(
                    context,
                    const EnergyWaterStatisticsScreen(),
                  ),
                ),

                DashboardMenuCard(
                  title: 'Submit Energy or Water Report',
                  subtitle:
                      'File a new citizen or field report with GPS coordinates, priority level, and category selection.',
                  badge: 'NEW REPORT',
                  icon: Icons.add_circle_outline_rounded,
                  color: AppColors.primaryDark,
                  onTap: () => openScreen(
                    context,
                    const EnergyWaterReportScreen(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardMenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}